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

class DesignDeliverablesScreen extends StatefulWidget {
  const DesignDeliverablesScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DesignDeliverablesScreen()),
    );
  }

  @override
  State<DesignDeliverablesScreen> createState() => _DesignDeliverablesScreenState();
}

class _DesignDeliverablesScreenState extends State<DesignDeliverablesScreen> {
  DesignDeliverablesData _data = DesignDeliverablesData();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = ProjectDataHelper.getData(context).designDeliverablesData;
      setState(() => _data = existing);
      if (existing.isEmpty) {
        _generateFromAi();
      }
    });
  }

  Future<void> _generateFromAi() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = ProjectDataHelper.getData(context);
      final contextText =
          ProjectDataHelper.buildFepContext(data, sectionLabel: 'Design Deliverables');
      final generated = await OpenAiServiceSecure()
          .generateDesignDeliverables(context: contextText);
      if (!mounted) return;
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'design_deliverables',
        dataUpdater: (current) => current.copyWith(
          designDeliverablesData: generated,
        ),
        showSnackbar: false,
      );
      if (!mounted) return;
      setState(() {
        _data = generated;
        _loading = false;
        _error = success ? null : 'Unable to save generated content.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to generate content. Please try again later.';
      });
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Design Deliverables'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final cardWidth = width;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(onBack: () => Navigator.maybePop(context)),
                            const SizedBox(height: 12),
                            const Text(
                              'Track design artifacts, approvals, and delivery readiness.',
                              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            const PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: 'Design Deliverables',
                              noteKey: 'design_deliverables_notes',
                              checkpoint: 'design_deliverables',
                              description: 'Summarize key deliverables, approvals, and handoff criteria.',
                            ),
                            const SizedBox(height: 24),
                            _MetricsRow(data: data),
                            if (_loading || _error != null) ...[
                              const SizedBox(height: 12),
                              _StatusBanner(isLoading: _loading, error: _error),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: cardWidth,
                              child: _DeliverablePipelineCard(items: data.pipeline),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: cardWidth,
                              child: _ApprovalStatusCard(items: data.approvals),
                            ),
                            const SizedBox(height: 24),
                            _DesignDeliverablesTable(rows: data.register),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: cardWidth,
                              child: _DesignDependenciesCard(items: data.dependencies),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: cardWidth,
                              child: _DesignHandoffCard(items: data.handoffChecklist),
                            ),
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => DesignPhaseScreen.open(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: const Color(0xFF111827),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Next', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              ),
                            ),
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

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
        const SizedBox(width: 16),
        const Text(
          'Design Deliverables',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
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
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
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
                  Text(primaryText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(role, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9CA3AF)),
            ],
          ),
        );
      },
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.data});

  final DesignDeliverablesData data;

  @override
  Widget build(BuildContext context) {
    final metrics = data.metrics;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(label: 'Active Deliverables', value: '${metrics.active}', accent: const Color(0xFF2563EB)),
        _MetricCard(label: 'In Review', value: '${metrics.inReview}', accent: const Color(0xFFF59E0B)),
        _MetricCard(label: 'Approved', value: '${metrics.approved}', accent: const Color(0xFF10B981)),
        _MetricCard(label: 'At Risk', value: '${metrics.atRisk}', accent: const Color(0xFFEF4444)),
      ],
    );
  }
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

class _DeliverablePipelineCard extends StatelessWidget {
  const _DeliverablePipelineCard({required this.items});

  final List<DesignDeliverablePipelineItem> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Deliverable Pipeline',
      subtitle: 'Progress across design stages.',
      child: Column(
        children: items.isNotEmpty
            ? items
                .map((item) => _PipelineRow(label: item.label, value: item.status))
                .toList()
            : const [
                _EmptyStateRow(message: 'No pipeline updates yet.'),
              ],
      ),
    );
  }
}

class _ApprovalStatusCard extends StatelessWidget {
  const _ApprovalStatusCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Approval Status',
      subtitle: 'Stakeholder sign-offs and gating items.',
      child: Column(
        children: items.isNotEmpty
            ? items.map((text) => _ChecklistRow(text: text)).toList()
            : const [
                _EmptyStateRow(message: 'No approvals tracked yet.'),
              ],
      ),
    );
  }
}

class _DesignDeliverablesTable extends StatelessWidget {
  const _DesignDeliverablesTable({required this.rows});

  final List<DesignDeliverableRegisterItem> rows;

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
            ...rows.map(
              (row) => _RegisterRow(
                name: row.name,
                owner: row.owner,
                status: row.status,
                due: row.due,
                risk: row.risk,
              ),
            ),
        ],
      ),
    );
  }
}

class _DesignDependenciesCard extends StatelessWidget {
  const _DesignDependenciesCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Design Dependencies',
      subtitle: 'Items that unblock delivery.',
      child: Column(
        children: items.isNotEmpty
            ? items.map((text) => _BulletRow(text: text)).toList()
            : const [
                _EmptyStateRow(message: 'No dependencies captured yet.'),
              ],
      ),
    );
  }
}

class _DesignHandoffCard extends StatelessWidget {
  const _DesignHandoffCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Design Handoff Checklist',
      subtitle: 'Ensure delivery-ready assets.',
      child: Column(
        children: items.isNotEmpty
            ? items.map((text) => _ChecklistRow(text: text)).toList()
            : const [
                _EmptyStateRow(message: 'No handoff items listed yet.'),
              ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});

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
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 16),
          child,
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
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
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
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
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
          child: Text('Deliverable', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Expanded(
          flex: 3,
          child: Text('Owner', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Expanded(
          flex: 2,
          child: Text('Status', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Expanded(
          flex: 2,
          child: Text('Due', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Expanded(
          flex: 2,
          child: Text('Risk', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
            child: Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF111827))),
          ),
          Expanded(
            flex: 3,
            child: Text(owner, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
          Expanded(
            flex: 2,
            child: Text(status, style: TextStyle(fontSize: 12, color: _statusColor(status))),
          ),
          Expanded(
            flex: 2,
            child: Text(due, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
          Expanded(
            flex: 2,
            child: Text(risk, style: TextStyle(fontSize: 12, color: _riskColor(risk))),
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
      child: Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
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
          Icon(isLoading ? Icons.auto_awesome : Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color))),
        ],
      ),
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
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4))),
        ],
      ),
    );
  }
}
