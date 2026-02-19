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
  State<OrganizationRolesResponsibilitiesScreen> createState() =>
      _OrganizationRolesResponsibilitiesScreenState();
}

class _OrganizationRolesResponsibilitiesScreenState
    extends State<OrganizationRolesResponsibilitiesScreen> {
  @override
  Widget build(BuildContext context) {
    final projectData = ProjectDataHelper.getData(context);
    final roles = projectData.projectRoles;

    final List<_MetricData> metrics = [
      _MetricData(
          'Total Roles', roles.length.toString(), const Color(0xFF3B82F6)),
      _MetricData(
          'Deciplines',
          roles.map<String>((r) => r.workstream).toSet().length.toString(),
          const Color(0xFF10B981)),
    ];

    final List<_SectionData> sections =
        roles.asMap().entries.map<_SectionData>((entry) {
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
        final newRole = RoleDefinition(
            title: 'New Role',
            description: 'Role description',
            workstream: 'Default');
        await ProjectDataHelper.saveAndNavigate(
          context: context,
          checkpoint: 'organization_roles_responsibilities',
          saveInBackground: true,
          nextScreenBuilder: () =>
              const OrganizationRolesResponsibilitiesScreen(),
          dataUpdater: (d) =>
              d.copyWith(projectRoles: [...d.projectRoles, newRole]),
        );
        setState(() {});
      },
      onAddPredefined: () => _showPredefinedRolesDialog(context),
    );
  }

  void _showPredefinedRolesDialog(BuildContext context) {
    final rootContext = context;
    final List<RoleDefinition> predefined = [
      RoleDefinition(
          title: 'Project Manager',
          description: 'Overall project leadership and coordination.',
          workstream: 'Management',
          isPredefined: true),
      RoleDefinition(
          title: 'Product Engineer',
          description:
              'Responsible for product design and technical specifications.',
          workstream: 'Engineering',
          isPredefined: true),
      RoleDefinition(
          title: 'Cost Person',
          description: 'Financial planning, budgeting, and cost control.',
          workstream: 'Finance',
          isPredefined: true),
      RoleDefinition(
          title: 'Developer',
          description: 'Software development and implementation.',
          workstream: 'Development',
          isPredefined: true),
      RoleDefinition(
          title: 'Tester',
          description: 'Quality assurance and testing of deliverables.',
          workstream: 'QA',
          isPredefined: true),
    ];

    final currentRoles =
        ProjectDataHelper.getProvider(context).projectData.projectRoles;
    final selectedIndices = <int>{};

    showDialog(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Standard Roles'),
          content: SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: predefined.length,
              itemBuilder: (context, index) {
                final role = predefined[index];
                final alreadyAdded =
                    currentRoles.any((r) => r.title == role.title);
                return CheckboxListTile(
                  title: Text(role.title),
                  subtitle: Text(role.workstream),
                  value: selectedIndices.contains(index) || alreadyAdded,
                  enabled: !alreadyAdded,
                  onChanged: alreadyAdded
                      ? null
                      : (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedIndices.add(index);
                            } else {
                              selectedIndices.remove(index);
                            }
                          });
                        },
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedIndices.isEmpty
                  ? null
                  : () async {
                      final newRoles =
                          selectedIndices.map((i) => predefined[i]).toList();
                      Navigator.pop(dialogContext);
                      await ProjectDataHelper.saveAndNavigate(
                        context: rootContext,
                        checkpoint: 'organization_roles_responsibilities',
                        saveInBackground: true,
                        nextScreenBuilder: () =>
                            const OrganizationRolesResponsibilitiesScreen(),
                        dataUpdater: (d) => d.copyWith(
                            projectRoles: [...d.projectRoles, ...newRoles]),
                      );
                      if (mounted) setState(() {});
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black),
              child: const Text('Add Selected'),
            ),
          ],
        ),
      ),
    );
  }

  void _editRole(BuildContext context, int index, RoleDefinition role) {
    final rootContext = context;
    final titleController = TextEditingController(text: role.title);
    final workstreamController = TextEditingController(text: role.workstream);
    final descController = TextEditingController(text: role.description);

    showDialog(
      context: rootContext,
      builder: (dialogContext) => PremiumEditDialog(
        title: 'Edit Role',
        icon: Icons.badge_outlined,
        onSave: () async {
          final updatedRoles = List<RoleDefinition>.from(
              ProjectDataHelper.getProvider(rootContext)
                  .projectData
                  .projectRoles);
          updatedRoles[index] = RoleDefinition(
            title: titleController.text.trim(),
            workstream: workstreamController.text.trim(),
            description: descController.text.trim(),
          );
          Navigator.pop(dialogContext);
          await ProjectDataHelper.saveAndNavigate(
            context: rootContext,
            checkpoint: 'organization_roles_responsibilities',
            saveInBackground: true,
            nextScreenBuilder: () =>
                const OrganizationRolesResponsibilitiesScreen(),
            dataUpdater: (d) => d.copyWith(projectRoles: updatedRoles),
          );
          if (mounted) setState(() {});
        },
        children: [
          PremiumEditDialog.fieldLabel('Title'),
          PremiumEditDialog.textField(
              controller: titleController, hint: 'e.g. Project Manager'),
          const SizedBox(height: 16),
          PremiumEditDialog.fieldLabel('Decipline'),
          PremiumEditDialog.textField(
              controller: workstreamController, hint: 'e.g. Management'),
          const SizedBox(height: 16),
          PremiumEditDialog.fieldLabel('Description'),
          PremiumEditDialog.textField(
              controller: descController,
              hint: 'Role responsibilities...',
              maxLines: 4),
        ],
      ),
    );
  }

  void _deleteRole(BuildContext context, int index) {
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Role'),
        content: const Text('Are you sure you want to delete this role?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final updatedRoles = List<RoleDefinition>.from(
                  ProjectDataHelper.getProvider(rootContext)
                      .projectData
                      .projectRoles);
              updatedRoles.removeAt(index);
              Navigator.pop(dialogContext);
              await ProjectDataHelper.saveAndNavigate(
                context: rootContext,
                checkpoint: 'organization_roles_responsibilities',
                saveInBackground: true,
                nextScreenBuilder: () =>
                    const OrganizationRolesResponsibilitiesScreen(),
                dataUpdater: (d) => d.copyWith(projectRoles: updatedRoles),
              );
              if (mounted) setState(() {});
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
  State<OrganizationStaffingPlanScreen> createState() =>
      _OrganizationStaffingPlanScreenState();
}

class _OrganizationStaffingPlanScreenState
    extends State<OrganizationStaffingPlanScreen> {
  bool _didAutoPopulate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didAutoPopulate) return;
      final provider = ProjectDataHelper.getProvider(context);
      final roles = provider.projectData.projectRoles;
      final requirements = provider.projectData.staffingRequirements;
      if (requirements.isEmpty && roles.isNotEmpty) {
        final newStaff = roles
            .map((role) => StaffingRequirement(
                  title: role.title,
                  startDate: 'TBD',
                  endDate: 'TBD',
                  employeeType: role.workstream == 'Engineering' ||
                          role.workstream == 'Development'
                      ? 'Contractor'
                      : 'Employee',
                ))
            .toList();
        await ProjectDataHelper.updateAndSave(
          context: context,
          checkpoint: 'organization_staffing_plan',
          dataUpdater: (d) => d.copyWith(
              staffingRequirements: [...d.staffingRequirements, ...newStaff]),
          showSnackbar: false,
        );
        if (mounted) {
          setState(() {
            _didAutoPopulate = true;
          });
        }
      } else {
        _didAutoPopulate = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectData = ProjectDataHelper.getData(context);
    final requirements = projectData.staffingRequirements;
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
              child: const InitiationLikeSidebar(
                activeItemLabel: 'Organization Plan - Staffing Plan',
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            _CircleIconButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () {
                                final navIdx =
                                    PlanningPhaseNavigation.getPageIndex(
                                        'organization_staffing_plan');
                                if (navIdx > 0) {
                                  final prevPage =
                                      PlanningPhaseNavigation.pages[navIdx - 1];
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: prevPage.builder));
                                } else {
                                  Navigator.maybePop(context);
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            _CircleIconButton(
                              icon: Icons.arrow_forward_ios_rounded,
                              onTap: () async {
                                final navIndex =
                                    PlanningPhaseNavigation.getPageIndex(
                                        'organization_staffing_plan');
                                if (navIndex != -1 &&
                                    navIndex <
                                        PlanningPhaseNavigation.pages.length -
                                            1) {
                                  final nextPage = PlanningPhaseNavigation
                                      .pages[navIndex + 1];
                                  await ProjectDataHelper.saveAndNavigate(
                                    context: context,
                                    checkpoint: 'organization_staffing_plan',
                                    saveInBackground: true,
                                    nextScreenBuilder: () =>
                                        nextPage.builder(context),
                                    dataUpdater: (d) => d,
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Staffing Plan',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827)),
                            ),
                            const Spacer(),
                            const _UserChip(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Plan resource needs, staffing timeline, and onboarding cadence.',
                          style:
                              TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 24),

                        // Metrics row
                        Row(
                          children: [
                            _MetricCard(
                                label: 'Total Staff',
                                value: requirements
                                    .fold<int>(0, (sum, r) => sum + r.headcount)
                                    .toString(),
                                accent: const Color(0xFFF59E0B)),
                            const SizedBox(width: 16),
                            _MetricCard(
                                label: 'Positions',
                                value: requirements.length.toString(),
                                accent: const Color(0xFF8B5CF6)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Staffing Table
                        if (requirements.isEmpty)
                          const _SectionEmptyState(
                            title: 'No staffing positions yet',
                            message:
                                'Sync from defined roles to populate this view.',
                            icon: Icons.group_outlined,
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 6)),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth),
                                      child: DataTable(
                                        dataRowMinHeight: 64.0,
                                        dataRowMaxHeight: 64.0,
                                        headingRowHeight: 56.0,
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                                const Color(0xFFF9FAFB)),
                                        headingTextStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF374151)),
                                        dataTextStyle: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF111827)),
                                        columnSpacing: 40,
                                        columns: const [
                                          DataColumn(label: Text('#')),
                                          DataColumn(label: Text('Position')),
                                          DataColumn(label: Text('Person')),
                                          DataColumn(label: Text('Location')),
                                          DataColumn(label: Text('Type')),
                                          DataColumn(label: Text('Status')),
                                          DataColumn(label: Text('Timeline')),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: requirements
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final index = entry.key;
                                          final req = entry.value;
                                          return DataRow(
                                            cells: [
                                              DataCell(Text('${index + 1}')),
                                              DataCell(Text(req.title,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600))),
                                              DataCell(Text(
                                                  req.personName.isEmpty
                                                      ? 'TBD'
                                                      : req.personName)),
                                              DataCell(Text(req.location.isEmpty
                                                  ? 'TBD'
                                                  : req.location)),
                                              DataCell(Text(
                                                  '${req.employmentType} / ${req.employeeType}')),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: req.status == 'Hired'
                                                        ? const Color(
                                                            0xFFD1FAE5)
                                                        : const Color(
                                                            0xFFFEF3C7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Text(
                                                    req.status.isEmpty
                                                        ? 'Open'
                                                        : req.status,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          req.status == 'Hired'
                                                              ? const Color(
                                                                  0xFF059669)
                                                              : const Color(
                                                                  0xFFD97706),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(Text(
                                                  '${req.startDate} → ${req.endDate}')),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.edit_outlined,
                                                          size: 18,
                                                          color: Color(
                                                              0xFF6B7280)),
                                                      onPressed: () =>
                                                          _editStaffing(context,
                                                              index, req),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.delete_outline,
                                                          size: 18,
                                                          color: Color(
                                                              0xFFEF4444)),
                                                      onPressed: () =>
                                                          _deleteStaffing(
                                                              context, index),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  const Positioned(
                      right: 24,
                      bottom: 24,
                      child: KazAiChatBubble(positioned: false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editStaffing(BuildContext context, int index, StaffingRequirement req) {
    final rootContext = context;
    final titleController = TextEditingController(text: req.title);
    final personController = TextEditingController(text: req.personName);
    final locationController = TextEditingController(text: req.location);
    final statusController = TextEditingController(text: req.status);
    final startController = TextEditingController(text: req.startDate);
    final endController = TextEditingController(text: req.endDate);
    String empType = req.employmentType;
    String employeeType = req.employeeType;

    showDialog(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PremiumEditDialog(
          title: 'Edit Staffing Requirement',
          icon: Icons.person_add_alt_1_outlined,
          onSave: () async {
            final updated = List<StaffingRequirement>.from(
                ProjectDataHelper.getProvider(rootContext)
                    .projectData
                    .staffingRequirements);
            updated[index] = req.copyWith(
              title: titleController.text.trim(),
              personName: personController.text.trim(),
              location: locationController.text.trim(),
              status: statusController.text.trim(),
              startDate: startController.text.trim(),
              endDate: endController.text.trim(),
              employmentType: empType,
              employeeType: employeeType,
            );
            Navigator.pop(dialogContext);
            await ProjectDataHelper.saveAndNavigate(
              context: rootContext,
              checkpoint: 'organization_staffing_plan',
              saveInBackground: true,
              nextScreenBuilder: () => const OrganizationStaffingPlanScreen(),
              dataUpdater: (d) => d.copyWith(staffingRequirements: updated),
            );
            if (mounted) setState(() {});
          },
          children: [
            PremiumEditDialog.fieldLabel('Job Title'),
            PremiumEditDialog.textField(
                controller: titleController, hint: 'e.g. Senior Developer'),
            const SizedBox(height: 16),
            PremiumEditDialog.fieldLabel('Person Name'),
            PremiumEditDialog.textField(
                controller: personController, hint: 'Assign to...'),
            const SizedBox(height: 16),
            PremiumEditDialog.fieldLabel('Location'),
            PremiumEditDialog.textField(
                controller: locationController,
                hint: 'e.g. Remote, Office, Site'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumEditDialog.fieldLabel('Employment'),
                      DropdownButtonFormField<String>(
                        initialValue: empType,
                        items: ['FT', 'PT']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setDialogState(() => empType = v!),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumEditDialog.fieldLabel('Category'),
                      DropdownButtonFormField<String>(
                        initialValue: employeeType,
                        items: ['Employee', 'Contractor']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => employeeType = v!),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
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
                      PremiumEditDialog.fieldLabel('Status'),
                      PremiumEditDialog.textField(
                          controller: statusController, hint: 'e.g. Hired'),
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
                      PremiumEditDialog.fieldLabel('Mobilization Date'),
                      PremiumEditDialog.textField(
                          controller: startController, hint: 'Q1 2024'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumEditDialog.fieldLabel('Release Date'),
                      PremiumEditDialog.textField(
                          controller: endController, hint: 'Q4 2024'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteStaffing(BuildContext context, int index) {
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Position'),
        content: const Text(
            'Are you sure you want to delete this staffing position?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final updated = List<StaffingRequirement>.from(
                  ProjectDataHelper.getProvider(rootContext)
                      .projectData
                      .staffingRequirements);
              updated.removeAt(index);
              Navigator.pop(dialogContext);
              await ProjectDataHelper.saveAndNavigate(
                context: rootContext,
                checkpoint: 'organization_staffing_plan',
                saveInBackground: true,
                nextScreenBuilder: () => const OrganizationStaffingPlanScreen(),
                dataUpdater: (d) => d.copyWith(staffingRequirements: updated),
              );
              if (mounted) setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PlanningSubsectionScreen extends StatelessWidget {
  const _PlanningSubsectionScreen(
      {required this.config, this.onAdd, this.onAddPredefined});

  final _PlanningSubsectionConfig config;
  final VoidCallback? onAdd;
  final VoidCallback? onAddPredefined;

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
                                final navIdx =
                                    PlanningPhaseNavigation.getPageIndex(
                                        config.checkpoint);
                                if (navIdx > 0) {
                                  final prevPage =
                                      PlanningPhaseNavigation.pages[navIdx - 1];
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: prevPage.builder));
                                } else {
                                  Navigator.maybePop(context);
                                }
                              },
                              onNext: () => _handleNext(context),
                              onAdd: onAdd,
                              onAddPredefined: onAddPredefined,
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
                      right: 24,
                      bottom: 24,
                      child: KazAiChatBubble(positioned: false)),
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
        saveInBackground: true,
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
  const _TopHeader(
      {required this.title,
      required this.onBack,
      this.onNext,
      this.onAdd,
      this.onAddPredefined});

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final VoidCallback? onAdd;
  final VoidCallback? onAddPredefined;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        _CircleIconButton(icon: Icons.arrow_forward_ios_rounded, onTap: onNext),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        const SizedBox(width: 24),
        if (onAddPredefined != null) ...[
          _yellowButton(
            label: onAddPredefined!.toString().contains('SyncRoles')
                ? 'Sync from Roles'
                : 'Standard Roles',
            icon: onAddPredefined!.toString().contains('SyncRoles')
                ? Icons.sync
                : Icons.assignment_outlined,
            onPressed: onAddPredefined!,
          ),
          const SizedBox(width: 12),
        ],
        if (onAdd != null)
          _yellowButton(
            label: 'Add Role',
            icon: Icons.add,
            onPressed: onAdd!,
          ),
        const Spacer(),
        const _UserChip(),
      ],
    );
  }

  Widget _yellowButton(
      {required String label,
      required IconData icon,
      required VoidCallback onPressed}) {
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
                  Text(displayName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(role,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF6B7280))),
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
    // ignore: unused_element_parameter
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
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF6B7280)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (data.onDelete != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: data.onDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFFEF4444)),
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
