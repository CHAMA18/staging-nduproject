import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/premium_edit_dialog.dart';

class OrganizationRolesResponsibilitiesScreen extends StatefulWidget {
  const OrganizationRolesResponsibilitiesScreen({super.key});

  @override
  State<OrganizationRolesResponsibilitiesScreen> createState() => _OrganizationRolesResponsibilitiesScreenState();
}

class _OrganizationRolesResponsibilitiesScreenState extends State<OrganizationRolesResponsibilitiesScreen> {
  @override
  Widget build(BuildContext context) {
    final projectData = ProjectDataHelper.getData(context);
    final roles = projectData.projectRoles;

    final List<_MetricData> metrics = [
      _MetricData('Total Roles', roles.length.toString(), const Color(0xFF3B82F6)),
      _MetricData('Workstreams', roles.map<String>((r) => r.workstream).toSet().length.toString(), const Color(0xFF10B981)),
    ];

    final List<_SectionData> sections = roles.asMap().entries.map<_SectionData>((entry) {
      final index = entry.key;
      final role = entry.value;
      return _SectionData(
        title: role.title,
        subtitle: role.workstream,
        bullets: [
          _BulletData(role.description, false),
        ],
        onEdit: () => _editRole(context, index, role),
        onDelete: () => _deleteRole(context, index),
      );
    }).toList();

    return _PlanningSubsectionScreen(
      config: _PlanningSubsectionConfig(
        title: 'Roles & Responsibilities',
        subtitle: 'Clarify ownership across workstreams and decision points.',
        noteKey: 'planning_organization_roles_responsibilities',
        checkpoint: 'organization_roles_responsibilities',
        activeItemLabel: 'Organization Plan - Roles & Responsibilities',
        metrics: metrics,
        sections: sections,
      ),
      onAdd: () async {
        final newRole = RoleDefinition(title: 'New Role', description: 'Role description', workstream: 'Default');
        await ProjectDataHelper.saveAndNavigate(
          context: context,
          checkpoint: 'organization_roles_responsibilities',
          nextScreenBuilder: () => const OrganizationRolesResponsibilitiesScreen(),
          dataUpdater: (d) => d.copyWith(projectRoles: [...d.projectRoles, newRole]),
        );
        setState(() {});
      },
    );
  }

  void _editRole(BuildContext context, int index, RoleDefinition role) {
    final titleController = TextEditingController(text: role.title);
    final workstreamController = TextEditingController(text: role.workstream);
    final descController = TextEditingController(text: role.description);

    showDialog(
      context: context,
      builder: (context) => PremiumEditDialog(
        title: 'Edit Role',
        icon: Icons.badge_outlined,
        onSave: () async {
          final updatedRoles = List<RoleDefinition>.from(ProjectDataHelper.getData(context).projectRoles);
          updatedRoles[index] = RoleDefinition(
            title: titleController.text.trim(),
            workstream: workstreamController.text.trim(),
            description: descController.text.trim(),
          );
          Navigator.pop(context);
          await ProjectDataHelper.saveAndNavigate(
            context: context,
            checkpoint: 'organization_roles_responsibilities',
            nextScreenBuilder: () => const OrganizationRolesResponsibilitiesScreen(),
            dataUpdater: (d) => d.copyWith(projectRoles: updatedRoles),
          );
          setState(() {});
        },
        children: [
          PremiumEditDialog.fieldLabel('Title'),
          PremiumEditDialog.textField(controller: titleController, hint: 'e.g. Project Manager'),
          const SizedBox(height: 16),
          PremiumEditDialog.fieldLabel('Workstream'),
          PremiumEditDialog.textField(controller: workstreamController, hint: 'e.g. Management'),
          const SizedBox(height: 16),
          PremiumEditDialog.fieldLabel('Description'),
          PremiumEditDialog.textField(controller: descController, hint: 'Role responsibilities...', maxLines: 4),
        ],
      ),
    );
  }

  void _deleteRole(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: const Text('Are you sure you want to delete this role?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final updatedRoles = List<RoleDefinition>.from(ProjectDataHelper.getData(context).projectRoles);
              updatedRoles.removeAt(index);
              Navigator.pop(context);
              await ProjectDataHelper.saveAndNavigate(
                context: context,
                checkpoint: 'organization_roles_responsibilities',
                nextScreenBuilder: () => const OrganizationRolesResponsibilitiesScreen(),
                dataUpdater: (d) => d.copyWith(projectRoles: updatedRoles),
              );
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class OrganizationStaffingPlanScreen extends StatefulWidget {
  const OrganizationStaffingPlanScreen({super.key});

  @override
  State<OrganizationStaffingPlanScreen> createState() => _OrganizationStaffingPlanScreenState();
}

class _OrganizationStaffingPlanScreenState extends State<OrganizationStaffingPlanScreen> {
  @override
  Widget build(BuildContext context) {
    final projectData = ProjectDataHelper.getData(context);
    final requirements = projectData.staffingRequirements;

    final List<_MetricData> metrics = [
      _MetricData('Total Staff', requirements.fold<int>(0, (sum, r) => sum + r.headcount).toString(), const Color(0xFFF59E0B)),
      _MetricData('Positions', requirements.length.toString(), const Color(0xFF8B5CF6)),
    ];

    final List<_SectionData> sections = requirements.asMap().entries.map<_SectionData>((entry) {
      final index = entry.key;
      final req = entry.value;
      return _SectionData(
        title: req.title,
        subtitle: '${req.startDate} to ${req.endDate}',
        statusRows: [
          _StatusRowData('Status', req.status, req.status == 'Hired' ? const Color(0xFF10B981) : const Color(0xFF6B7280)),
          _StatusRowData('Headcount', req.headcount.toString(), const Color(0xFF3B82F6)),
        ],
        onEdit: () => _editStaffing(context, index, req),
        onDelete: () => _deleteStaffing(context, index),
      );
    }).toList();

    return _PlanningSubsectionScreen(
      config: _PlanningSubsectionConfig(
        title: 'Staffing Plan',
        subtitle: 'Plan resource needs, staffing timeline, and onboarding cadence.',
        noteKey: 'planning_organization_staffing_plan',
        checkpoint: 'organization_staffing_plan',
        activeItemLabel: 'Organization Plan - Staffing Plan',
        metrics: metrics,
        sections: sections,
      ),
      onAdd: () async {
        final newReq = StaffingRequirement(title: 'New Position', startDate: 'TBD', endDate: 'TBD');
        await ProjectDataHelper.saveAndNavigate(
          context: context,
          checkpoint: 'organization_staffing_plan',
          nextScreenBuilder: () => const OrganizationStaffingPlanScreen(),
          dataUpdater: (d) => d.copyWith(staffingRequirements: [...d.staffingRequirements, newReq]),
        );
        setState(() {});
      },
    );
  }

  void _editStaffing(BuildContext context, int index, StaffingRequirement req) {
    final titleController = TextEditingController(text: req.title);
    final headcountController = TextEditingController(text: req.headcount.toString());
    final statusController = TextEditingController(text: req.status);
    final startController = TextEditingController(text: req.startDate);
    final endController = TextEditingController(text: req.endDate);

    showDialog(
      context: context,
      builder: (context) => PremiumEditDialog(
        title: 'Edit Staffing Requirement',
        icon: Icons.person_add_alt_1_outlined,
        onSave: () async {
          final updated = List<StaffingRequirement>.from(ProjectDataHelper.getData(context).staffingRequirements);
          updated[index] = StaffingRequirement(
            title: titleController.text.trim(),
            headcount: int.tryParse(headcountController.text) ?? 1,
            status: statusController.text.trim(),
            startDate: startController.text.trim(),
            endDate: endController.text.trim(),
          );
          Navigator.pop(context);
          await ProjectDataHelper.saveAndNavigate(
            context: context,
            checkpoint: 'organization_staffing_plan',
            nextScreenBuilder: () => const OrganizationStaffingPlanScreen(),
            dataUpdater: (d) => d.copyWith(staffingRequirements: updated),
          );
          setState(() {});
        },
        children: [
          PremiumEditDialog.fieldLabel('Job Title'),
          PremiumEditDialog.textField(controller: titleController, hint: 'e.g. Senior Developer'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumEditDialog.fieldLabel('Headcount'),
                    PremiumEditDialog.textField(controller: headcountController, keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumEditDialog.fieldLabel('Status'),
                    PremiumEditDialog.textField(controller: statusController, hint: 'e.g. Planned'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumEditDialog.fieldLabel('Start Date'),
                    PremiumEditDialog.textField(controller: startController, hint: 'Q1 2024'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumEditDialog.fieldLabel('End Date'),
                    PremiumEditDialog.textField(controller: endController, hint: 'Q4 2024'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteStaffing(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Position'),
        content: const Text('Are you sure you want to delete this staffing position?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final updated = List<StaffingRequirement>.from(ProjectDataHelper.getData(context).staffingRequirements);
              updated.removeAt(index);
              Navigator.pop(context);
              await ProjectDataHelper.saveAndNavigate(
                context: context,
                checkpoint: 'organization_staffing_plan',
                nextScreenBuilder: () => const OrganizationStaffingPlanScreen(),
                dataUpdater: (d) => d.copyWith(staffingRequirements: updated),
              );
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PlanningSubsectionScreen extends StatelessWidget {
  const _PlanningSubsectionScreen({required this.config, this.onAdd});

  final _PlanningSubsectionConfig config;
  final VoidCallback? onAdd;

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
              child: InitiationLikeSidebar(
                  activeItemLabel: config.activeItemLabel),
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
                        const gap = 24.0;
                        final twoCol = width >= 980;
                        final halfWidth = twoCol ? (width - gap) / 2 : width;
                        final hasContent = config.metrics.isNotEmpty ||
                            config.sections.isNotEmpty;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(
                                title: config.title,
                                onBack: () {
                                  final navIdx = PlanningPhaseNavigation.getPageIndex(config.checkpoint);
                                  if (navIdx > 0) {
                                    final prevPage = PlanningPhaseNavigation.pages[navIdx - 1];
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: prevPage.builder));
                                  } else {
                                    Navigator.maybePop(context);
                                  }
                                },
                                onNext: () => _handleNext(context),
                                onAdd: onAdd,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              config.subtitle,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: config.title,
                              noteKey: config.noteKey,
                              checkpoint: config.checkpoint,
                              description:
                                  'Capture ownership, staffing needs, and role coverage.',
                            ),
                            const SizedBox(height: 24),
                            if (hasContent) ...[
                              _MetricsRow(metrics: config.metrics),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: config.sections
                                    .map((section) => SizedBox(
                                        width: halfWidth,
                                        child: _SectionCard(data: section)))
                                    .toList(),
                              ),
                            ] else
                              const _SectionEmptyState(
                                title: 'No staffing details yet',
                                message:
                                    'Add roles, responsibilities, and staffing notes to populate this view.',
                                icon: Icons.group_outlined,
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
  void _handleNext(BuildContext context) async {
    final navIndex = PlanningPhaseNavigation.getPageIndex(config.checkpoint);
    if (navIndex != -1 && navIndex < PlanningPhaseNavigation.pages.length - 1) {
      final nextPage = PlanningPhaseNavigation.pages[navIndex + 1];
      await ProjectDataHelper.saveAndNavigate(
        context: context,
        checkpoint: config.checkpoint,
        nextScreenBuilder: () => nextPage.builder(context),
        dataUpdater: (d) => d,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No next screen available')),
      );
    }
  }
}

class _PlanningSubsectionConfig {
  _PlanningSubsectionConfig({
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
  const _TopHeader({required this.title, required this.onBack, this.onNext, this.onAdd});

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        _CircleIconButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: onNext),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        const SizedBox(width: 24),
        if (onAdd != null)
          _yellowButton(
            label: 'Add Item',
            icon: Icons.add,
            onPressed: onAdd!,
          ),
        const Spacer(),
        const _UserChip(),
      ],
    );
  }

  Widget _yellowButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
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
            backgroundImage:
                user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151)),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          StreamBuilder<bool>(
            stream: UserService.watchAdminStatus(),
            builder: (context, snapshot) {
              final email = user?.email ?? '';
              final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
              final role = isAdmin ? 'Admin' : 'Member';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(role, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                ],
              );
            },
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down,
              size: 18, color: Color(0xFF9CA3AF)),
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
          .map((metric) => _MetricCard(
              label: metric.label, value: metric.value, accent: metric.color))
          .toList(),
    );
  }
}

class _MetricData {
  _MetricData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label, required this.value, required this.accent});

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
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
  }
}

class _SectionData {
  _SectionData({
    required this.title,
    required this.subtitle,
    this.bullets = const [],
    this.statusRows = const [],
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final List<_BulletData> bullets;
  final List<_StatusRowData> statusRows;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
}

class _BulletData {
  _BulletData(this.text, this.isCheck);

  final String text;
  final bool isCheck;
}

class _StatusRowData {
  _StatusRowData(this.label, this.value, this.color);

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
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(data.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
              ),
              if (data.onEdit != null || data.onDelete != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data.onEdit != null)
                      IconButton(
                        onPressed: data.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6B7280)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (data.onDelete != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: data.onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(data.subtitle,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
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
            color: data.isCheck
                ? const Color(0xFF10B981)
                : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.text,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF374151), height: 1.4),
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
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: data.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState(
      {required this.title, required this.message, required this.icon});

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
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(message,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
