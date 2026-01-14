import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeamRolesResponsibilitiesScreen extends StatefulWidget {
  const TeamRolesResponsibilitiesScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeamRolesResponsibilitiesScreen()),
    );
  }

  @override
  State<TeamRolesResponsibilitiesScreen> createState() => _TeamRolesResponsibilitiesScreenState();
}

class _TeamRolesResponsibilitiesScreenState extends State<TeamRolesResponsibilitiesScreen> {
  late List<_RoleCardData> _members;

  @override
  void initState() {
    super.initState();
    // Reflect the current team: for now, only the project owner (signed-in user).
    final user = FirebaseAuth.instance.currentUser;
    final displayName = ((user?.displayName?.trim().isNotEmpty ?? false)
            ? user!.displayName!.trim()
            : (user?.email?.trim().isNotEmpty ?? false)
                ? user!.email!.trim()
                : 'Owner')
        .toString();
    final ownerEmail = user?.email?.trim() ?? '';

    final starterMember = _RoleCardData(
      title: 'Project Owner',
      subtitle: [
        if (displayName.isNotEmpty) displayName,
        'Core team',
        'Full access',
      ].join(' • '),
      responsibilities: const [
        'Define objectives and success criteria',
        'Approve scope and budgets',
        'Remove blockers and align stakeholders',
      ],
      workItems: const [
        _WorkItem(name: 'Develop rollout plan', status: 'Done', isAltRow: false),
        _WorkItem(name: 'Prepare kickoff agenda', status: 'In progress', isAltRow: true),
      ],
      fullName: displayName,
      role: 'Owner',
      email: ownerEmail,
      phone: '',
      department: '',
      location: '',
      startDate: DateTime.now(),
      teamPlacement: 'Core team',
      accessLevel: 'Full access',
      notes: 'Default owner profile. Add members to expand your team.',
    );

    // Seed with only the owner.
    _members = <_RoleCardData>[starterMember];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                activeItemLabel: 'Roles & Responsibilities',
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 32,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Back navigation placed before the title text
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F1F1F)),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Manage Roles & Responsibilites',
                                style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F1F1F),
                                    ) ??
                                    const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F1F1F),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _YellowActionButton(
                              label: 'Add New Member',
                              icon: Icons.add,
                              onPressed: () => _showMemberDialog(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            const spacing = 24.0;
                            final cardWidth = maxWidth >= 1080
                                ? (maxWidth - spacing * 2) / 3
                                : maxWidth >= 720
                                    ? (maxWidth - spacing) / 2
                                    : maxWidth;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: _members.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value;
                                return SizedBox(
                                  width: cardWidth,
                                  child: _RoleCard(
                                    data: data,
                                    onEdit: () => _showMemberDialog(editIndex: index),
                                    onDelete: () => _confirmDeleteMember(index),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
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

  Future<void> _showMemberDialog({int? editIndex}) async {
    final existing = editIndex != null ? _members[editIndex] : null;
    final result = await showDialog<_RoleCardData>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (_) => _TeamMemberDialog(initialData: existing),
    );

    if (result == null) {
      return;
    }

    setState(() {
      final updated = List<_RoleCardData>.from(_members);
      if (editIndex != null) {
        updated[editIndex] = result;
      } else {
        updated.add(result);
      }
      _members = updated;
    });
  }

  Future<void> _confirmDeleteMember(int index) async {
    final member = _members[index];
    final displayName = member.fullName.isNotEmpty ? member.fullName : member.title;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Remove team member?'),
          content: Text(
            'This will remove $displayName from the list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        final updated = List<_RoleCardData>.from(_members)..removeAt(index);
        _members = updated;
      });
    }
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  final _RoleCardData data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14212527),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E7FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business_center_outlined, color: Color(0xFF6C6CF3)),
              ),
              const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       data.title,
                       style: const TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.w700,
                         color: Color(0xFF202326),
                       ),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       data.subtitle,
                       style: const TextStyle(
                         fontSize: 13,
                         height: 1.4,
                         color: Color(0xFF5B6572),
                       ),
                     ),
                   ],
                 ),
               ),
               Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   IconButton(
                     tooltip: 'Edit member',
                     onPressed: onEdit,
                     icon: const Icon(Icons.edit_outlined, color: Color(0xFF5B6572)),
                   ),
                   IconButton(
                     tooltip: 'Delete member',
                     onPressed: onDelete,
                     icon: const Icon(Icons.delete_outline, color: Color(0xFFD64545)),
                   ),
                 ],
               ),
            ],
          ),
          const SizedBox(height: 20),
           const Text(
             'Key Responsibilities',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202326),
            ),
          ),
          const SizedBox(height: 12),
          ...data.responsibilities.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF42D79E), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${index + 1}. $item',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF394452),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFD0D6E4), thickness: 1),
          const SizedBox(height: 16),
          const Text(
            'Work Progress',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202326),
            ),
          ),
          const SizedBox(height: 12),
          const _WorkProgressHeader(),
          const SizedBox(height: 12),
          ...data.workItems.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: item == data.workItems.last ? 0 : 10),
              child: _WorkProgressRow(item: item),
            );
          }),
        ],
      ),
    );
  }
}

class _WorkProgressHeader extends StatelessWidget {
  const _WorkProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: Text(
            'Name',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Status',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkProgressRow extends StatelessWidget {
  const _WorkProgressRow({required this.item});

  final _WorkItem item;

  @override
  Widget build(BuildContext context) {
    final background = item.isAltRow ? const Color(0xFFF2F4F7) : Colors.transparent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5563),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F8EE),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  item.status,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2FB379),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCardData {
  const _RoleCardData({
    required this.title,
    required this.subtitle,
    required this.responsibilities,
    required this.workItems,
    this.fullName = '',
    this.role = '',
    this.email = '',
    this.phone = '',
    this.department = '',
    this.location = '',
    this.startDate,
    this.teamPlacement = 'Core team',
    this.accessLevel = 'Full access',
    this.notes = '',
  });

  final String title;
  final String subtitle;
  final List<String> responsibilities;
  final List<_WorkItem> workItems;
  final String fullName;
  final String role;
  final String email;
  final String phone;
  final String department;
  final String location;
  final DateTime? startDate;
  final String teamPlacement;
  final String accessLevel;
  final String notes;
}

class _WorkItem {
  const _WorkItem({
    required this.name,
    required this.status,
    this.isAltRow = false,
  });

  final String name;
  final String status;
  final bool isAltRow;
}

class _WorkProgressDraft {
  _WorkProgressDraft({String initialName = '', String initialStatus = 'Not started'})
      : nameController = TextEditingController(text: initialName),
        status = initialStatus;

  final TextEditingController nameController;
  String status;

  void dispose() {
    nameController.dispose();
  }
}

class _WorkProgressEntryEditor extends StatelessWidget {
  const _WorkProgressEntryEditor({
    required this.index,
    required this.draft,
    required this.statusOptions,
    required this.onStatusChanged,
    this.onRemove,
  });

  final int index;
  final _WorkProgressDraft draft;
  final List<String> statusOptions;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ) ??
        TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        );
    final borderRadius = BorderRadius.circular(18);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: borderRadius,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('Work item ${index + 1}', style: titleStyle),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  splashRadius: 22,
                  icon: Icon(Icons.delete_outline, color: colors.error.withOpacity(0.85)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: draft.nameController,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
            decoration: InputDecoration(
              labelText: 'Work item name',
              hintText: 'e.g. Draft integration plan',
              prefixIcon: Icon(Icons.task_alt_outlined, color: colors.primary),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withOpacity(0.4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.primary, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: draft.status,
            onChanged: (value) {
              if (value == null) return;
              onStatusChanged(value);
            },
            items: statusOptions
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  ),
                )
                .toList(),
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
            decoration: InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.flag_outlined, color: colors.primary),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withOpacity(0.4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.primary, width: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YellowActionButton extends StatelessWidget {
  const _YellowActionButton({
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final baseStyle = ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: const Color(0xFFFFC400),
      foregroundColor: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ).copyWith(
      iconColor: const WidgetStatePropertyAll(Color(0xFF1F1F1F)),
    );

    final text = Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F1F1F),
      ),
    );

    if (icon == null) {
      return ElevatedButton(
        onPressed: onPressed,
        style: baseStyle.copyWith(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
        child: text,
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      style: baseStyle.copyWith(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      icon: Icon(icon, color: const Color(0xFF1F1F1F)),
      label: text,
    );
  }
}

class _TeamMemberDialog extends StatefulWidget {
  const _TeamMemberDialog({this.initialData});

  final _RoleCardData? initialData;

  @override
  State<_TeamMemberDialog> createState() => _TeamMemberDialogState();
}

class _TeamMemberDialogState extends State<_TeamMemberDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = _isEditing ? 'Edit team member' : 'Add team member';
    final subtitle = _isEditing
        ? 'Update role ownership and responsibilities.'
        : 'Define role ownership and responsibilities.';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final width = constraints.maxWidth;
            final twoCol = width >= 640;
            final fieldWidth = twoCol ? (width - gap) / 2 : width;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.group_add_outlined, color: colors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.onSurface,
                                  ) ??
                                  TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: colors.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ) ??
                                  TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: colors.outline),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(label: 'Identity'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: _DialogTextField(
                          controller: _nameController,
                          label: 'Full name',
                          hint: 'e.g. Ama Kwame',
                          icon: Icons.person_outline,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _DialogTextField(
                          controller: _roleController,
                          label: 'Role title',
                          hint: 'e.g. Project Manager',
                          icon: Icons.work_outline,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _DialogTextField(
                          controller: _emailController,
                          label: 'Work email',
                          hint: 'name@company.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _DialogTextField(
                          controller: _phoneController,
                          label: 'Phone number',
                          hint: 'e.g. +233 24 000 0000',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _DialogTextField(
                          controller: _departmentController,
                          label: 'Department',
                          hint: 'e.g. Product',
                          icon: Icons.apartment_outlined,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _DialogTextField(
                          controller: _locationController,
                          label: 'Location',
                          hint: 'e.g. Accra (GMT)',
                          icon: Icons.place_outlined,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: _DateSelector(
                          label: 'Start date',
                          hint: 'Select date',
                          value: _startDate,
                          onSelect: (date) => setState(() => _startDate = date),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ChoicePills(
                    label: 'Team placement',
                    options: const ['Core team', 'Extended team', 'External partner'],
                    selectedValue: _teamPlacement,
                    onChanged: (value) => setState(() => _teamPlacement = value),
                  ),
                  const SizedBox(height: 20),
                  _ChoicePills(
                    label: 'Access level',
                    options: const ['Full access', 'Limited access', 'View only'],
                    selectedValue: _accessLevel,
                    onChanged: (value) => setState(() => _accessLevel = value),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel(label: 'Responsibilities'),
                  const SizedBox(height: 12),
                  _DialogTextField(
                    controller: _responsibilitiesController,
                    label: 'Key responsibilities',
                    hint: 'Add key responsibilities, one per line',
                    icon: Icons.list_alt_outlined,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel(label: 'Work progress'),
                  const SizedBox(height: 12),
                  ..._workProgressEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final draft = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _workProgressEntries.length - 1 ? 0 : 12,
                      ),
                      child: _WorkProgressEntryEditor(
                        index: index,
                        draft: draft,
                        statusOptions: _statusOptions,
                        onStatusChanged: (value) => setState(() => draft.status = value),
                        onRemove: _workProgressEntries.length > 1
                            ? () => _removeWorkProgressEntry(index)
                            : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _addWorkProgressEntry,
                    icon: const Icon(Icons.add),
                    label: const Text('Add work item'),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel(label: 'Notes'),
                  const SizedBox(height: 12),
                  _DialogTextField(
                    controller: _notesController,
                    label: 'Additional notes',
                    hint: 'Optional notes about this team member',
                    icon: Icons.note_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      _YellowActionButton(
                        label: _isEditing ? 'Save changes' : 'Add member',
                        icon: Icons.check_circle_outline,
                        onPressed: _handleSaveMember,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _locationController = TextEditingController();
  final _responsibilitiesController = TextEditingController();
  final _notesController = TextEditingController();
  final List<_WorkProgressDraft> _workProgressEntries = [];

  static const List<String> _statusOptions = ['Not started', 'In progress', 'Blocked', 'Done'];

  String _accessLevel = 'Full access';
  String _teamPlacement = 'Core team';
  DateTime? _startDate;

  bool get _isEditing => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    if (initial != null) {
      _nameController.text = initial.fullName;
      _roleController.text = initial.role;
      _emailController.text = initial.email;
      _phoneController.text = initial.phone;
      _departmentController.text = initial.department;
      _locationController.text = initial.location;
      _notesController.text = initial.notes;
      _startDate = initial.startDate;
      _teamPlacement = initial.teamPlacement;
      _accessLevel = initial.accessLevel;

      if (initial.responsibilities.isNotEmpty) {
        final buffer = StringBuffer();
        for (var i = 0; i < initial.responsibilities.length; i++) {
          buffer.writeln('${i + 1}. ${initial.responsibilities[i]}');
        }
        _responsibilitiesController.text = buffer.toString().trimRight();
      }

      if (initial.workItems.isNotEmpty) {
        _workProgressEntries.addAll(
          initial.workItems.map(
            (item) => _WorkProgressDraft(
              initialName: item.name,
              initialStatus: item.status,
            ),
          ),
        );
      }
    }

    if (_workProgressEntries.isEmpty) {
      _workProgressEntries.add(_WorkProgressDraft(initialStatus: _statusOptions.first));
    }
  }

  void _handleSaveMember() {
    final responsibilities = _extractResponsibilities(_responsibilitiesController.text);

    if (responsibilities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one key responsibility before saving.')),
      );
      return;
    }

    final workItems = <_WorkItem>[];
    for (final entry in _workProgressEntries) {
      final trimmedName = entry.nameController.text.trim();
      if (trimmedName.isEmpty) {
        continue;
      }
      final isAltRow = workItems.length.isOdd;
      workItems.add(
        _WorkItem(
          name: trimmedName,
          status: entry.status,
          isAltRow: isAltRow,
        ),
      );
    }

    final fullName = _nameController.text.trim();
    final role = _roleController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final department = _departmentController.text.trim();
    final location = _locationController.text.trim();
    final notes = _notesController.text.trim();
    final teamTitle = role.isNotEmpty
        ? role
        : fullName.isNotEmpty
            ? fullName
            : 'Team Member';

    final subtitleParts = <String>[];
    if (fullName.isNotEmpty && fullName != teamTitle) {
      subtitleParts.add(fullName);
    }
    if (department.isNotEmpty) {
      subtitleParts.add(department);
    }
    if (location.isNotEmpty) {
      subtitleParts.add(location);
    }
    subtitleParts.add(_teamPlacement);
    subtitleParts.add(_accessLevel);

    final subtitle = subtitleParts.where((element) => element.trim().isNotEmpty).join(' • ');

    final member = _RoleCardData(
      title: teamTitle,
      subtitle: subtitle.isEmpty
          ? 'Team member'
          : subtitle,
      responsibilities: responsibilities,
      workItems: workItems,
      fullName: fullName,
      role: role,
      email: email,
      phone: phone,
      department: department,
      location: location,
      startDate: _startDate,
      teamPlacement: _teamPlacement,
      accessLevel: _accessLevel,
      notes: notes,
    );

    Navigator.of(context).pop(member);
  }

  List<String> _extractResponsibilities(String raw) {
    final lines = raw.split(RegExp(r'[\r\n]+'));
    final cleaned = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final match = RegExp(r'^\d+[\).\-]*\s*').firstMatch(trimmed);
      final withoutNumber = match != null ? trimmed.substring(match.end).trimLeft() : trimmed;
      if (withoutNumber.isNotEmpty) {
        cleaned.add(withoutNumber);
      }
    }
    return cleaned;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _locationController.dispose();
    _responsibilitiesController.dispose();
    _notesController.dispose();
    for (final entry in _workProgressEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addWorkProgressEntry() {
    setState(() {
      _workProgressEntries.add(_WorkProgressDraft(initialStatus: _statusOptions.first));
    });
  }

  void _removeWorkProgressEntry(int index) {
    if (index < 0 || index >= _workProgressEntries.length) {
      return;
    }
    setState(() {
      final removed = _workProgressEntries.removeAt(index);
      removed.dispose();
      if (_workProgressEntries.isEmpty) {
        _workProgressEntries.add(_WorkProgressDraft(initialStatus: _statusOptions.first));
      }
    });
  }

  // --- AI Suggestion Helper (now in dialog state) ---
  Future<String> fetchOpenAiSuggestion(String field) async {
    // Replace with your actual OpenAI API key and endpoint
    const apiKey = 'YOUR_OPENAI_API_KEY';
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final prompt = _buildPromptForField(field);
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {'role': 'system', 'content': 'You are an expert HR assistant for software teams.'},
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 60,
        'temperature': 0.7,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final suggestion = data['choices'][0]['message']['content']?.trim();
      return suggestion ?? '';
    } else {
      return '';
    }
  }

  String _buildPromptForField(String field) {
    switch (field) {
      case 'full_name':
        return 'Suggest a realistic full name for a software project team member.';
      case 'role_title':
        return 'Suggest a world-class role/title for a software project team (e.g., Project Manager, QA Lead, DevOps Engineer).';
      case 'work_email':
        return 'Suggest a professional work email address for a team member named Ama Kwame.';
      case 'phone_number':
        return 'Suggest a realistic phone number for a team member in Ghana.';
      case 'department':
        return 'Suggest a department for a software project team member (e.g., IT, Engineering, Product).';
      case 'location':
        return 'Suggest a location or time zone for a remote software team member.';
      case 'responsibilities':
        return 'Suggest 3-5 key responsibilities for a world-class software project team member.';
      default:
        return 'Suggest a value for $field.';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ) ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        );

    return Text(label, style: style);
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const _DialogTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelStyle = theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant);
    final hintTextStyle = theme.textTheme.bodyMedium?.copyWith(color: colors.outline);
    final inputBorderRadius = BorderRadius.circular(16);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, color: colors.primary),
        suffixIcon: suffixIcon,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: labelStyle,
        hintStyle: hintTextStyle,
        enabledBorder: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _ChoicePills extends StatelessWidget {
  const _ChoicePills({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.pillColor,
    this.selectedColor,
  });

  final String label;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final Color? pillColor;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final chipColor = pillColor ?? colors.surfaceContainerHighest.withOpacity(0.6);
    final activeColor = selectedColor ?? colors.primary;
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: colors.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: labelStyle,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final bool isSelected = option == selectedValue;
            return ChoiceChip(
              label: Text(
                option,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(option),
              selectedColor: activeColor,
              backgroundColor: chipColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.hint,
    required this.value,
    required this.onSelect,
  });

  final String label;
  final String hint;
  final DateTime? value;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelStyle = theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant);
    final borderRadius = BorderRadius.circular(16);
    final displayValue = value != null ? _formatDate(value!) : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
          builder: (context, child) {
            final dateTheme = theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: colors.primary,
                onPrimary: colors.onPrimary,
                surface: colors.surface,
                onSurface: colors.onSurface,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: colors.primary),
              ),
            );
            return Theme(data: dateTheme, child: child!);
          },
        );
        if (picked != null) {
          onSelect(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: colors.surfaceContainerHighest.withOpacity(0.4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          labelStyle: labelStyle,
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: colors.primary, width: 1.6),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: value == null ? colors.outline : colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayValue ?? hint,
                style: TextStyle(
                  fontSize: 14,
                  color: displayValue == null ? colors.outline : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

// --- Firestore CRUD for Roles & Responsibilities ---
final _rolesCollection = FirebaseFirestore.instance.collection('organization_roles');

Future<void> addOrUpdateRole(String docId, Map<String, dynamic> data) async {
  await _rolesCollection.doc(docId).set(data, SetOptions(merge: true));
}

Future<void> deleteRole(String docId) async {
  await _rolesCollection.doc(docId).delete();
}

Stream<List<Map<String, dynamic>>> getRolesStream() {
  return _rolesCollection.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
}
