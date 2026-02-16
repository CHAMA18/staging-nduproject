import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_activity.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';

class ProjectActivitiesLogScreen extends StatefulWidget {
  const ProjectActivitiesLogScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectActivitiesLogScreen()),
    );
  }

  @override
  State<ProjectActivitiesLogScreen> createState() =>
      _ProjectActivitiesLogScreenState();
}

class _ProjectActivitiesLogScreenState
    extends State<ProjectActivitiesLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedPhase = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ProjectDataHelper.getData(context);
    final activities = List<ProjectActivity>.from(data.projectActivities)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final phaseOptions = _phaseOptions(activities);
    final filteredActivities = _applyFilters(activities);

    final totalCount = activities.length;
    final pendingCount = activities
        .where((activity) => activity.status == ProjectActivityStatus.pending)
        .length;
    final implementedCount = activities
        .where(
            (activity) => activity.status == ProjectActivityStatus.implemented)
        .length;
    final approvedCount = activities
        .where((activity) =>
            activity.approvalStatus == ProjectApprovalStatus.approved)
        .length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                activeItemLabel: 'Project Activities Log',
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  const AdminEditToggle(),
                  Column(
                    children: [
                      const FrontEndPlanningHeader(
                          title: 'Project Activities Log'),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Track generated project activities, ownership, and status across phases.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _StatCard(
                                    title: 'Total Activities',
                                    value: '$totalCount',
                                    color: const Color(0xFF0EA5E9),
                                  ),
                                  _StatCard(
                                    title: 'Pending',
                                    value: '$pendingCount',
                                    color: const Color(0xFFF59E0B),
                                  ),
                                  _StatCard(
                                    title: 'Implemented',
                                    value: '$implementedCount',
                                    color: const Color(0xFF10B981),
                                  ),
                                  _StatCard(
                                    title: 'Approved',
                                    value: '$approvedCount',
                                    color: const Color(0xFF6366F1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB)),
                                ),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 320,
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (value) => setState(() {
                                          _searchQuery =
                                              value.trim().toLowerCase();
                                        }),
                                        decoration: InputDecoration(
                                          hintText:
                                              'Search activity, owner, role, phase...',
                                          isDense: true,
                                          prefixIcon: const Icon(Icons.search,
                                              size: 20,
                                              color: Color(0xFF6B7280)),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFE5E7EB)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFE5E7EB)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    _FilterDropdown(
                                      width: 180,
                                      label: 'Status',
                                      value: _selectedStatus,
                                      items: const [
                                        'All',
                                        'Pending',
                                        'Acknowledged',
                                        'Implemented',
                                        'Deferred',
                                        'Rejected',
                                      ],
                                      onChanged: (value) => setState(() {
                                        _selectedStatus = value ?? 'All';
                                      }),
                                    ),
                                    _FilterDropdown(
                                      width: 220,
                                      label: 'Phase',
                                      value: _selectedPhase,
                                      items: phaseOptions,
                                      onChanged: (value) => setState(() {
                                        _selectedPhase = value ?? 'All';
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _ActivitiesTable(
                                activities: filteredActivities,
                                statusLabel: _statusLabel,
                                approvalLabel: _approvalLabel,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

  List<ProjectActivity> _applyFilters(List<ProjectActivity> activities) {
    return activities.where((activity) {
      if (_selectedStatus != 'All' &&
          _statusLabel(activity.status) != _selectedStatus) {
        return false;
      }
      final phase =
          activity.phase.trim().isEmpty ? 'Unspecified' : activity.phase;
      if (_selectedPhase != 'All' && phase != _selectedPhase) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;

      final text = [
        activity.title,
        activity.description,
        activity.phase,
        activity.discipline,
        activity.role,
        activity.assignedTo ?? '',
        activity.sourceSection,
        activity.applicableSections.join(' '),
      ].join(' ').toLowerCase();

      return text.contains(_searchQuery);
    }).toList();
  }

  List<String> _phaseOptions(List<ProjectActivity> activities) {
    final phases = activities
        .map((activity) =>
            activity.phase.trim().isEmpty ? 'Unspecified' : activity.phase)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...phases];
  }

  String _statusLabel(ProjectActivityStatus status) {
    switch (status) {
      case ProjectActivityStatus.pending:
        return 'Pending';
      case ProjectActivityStatus.acknowledged:
        return 'Acknowledged';
      case ProjectActivityStatus.implemented:
        return 'Implemented';
      case ProjectActivityStatus.rejected:
        return 'Rejected';
      case ProjectActivityStatus.deferred:
        return 'Deferred';
    }
  }

  String _approvalLabel(ProjectApprovalStatus status) {
    switch (status) {
      case ProjectApprovalStatus.draft:
        return 'Draft';
      case ProjectApprovalStatus.approved:
        return 'Approved';
      case ProjectApprovalStatus.locked:
        return 'Locked';
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final selectedValue = items.contains(value) ? value : items.first;
    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _ActivitiesTable extends StatelessWidget {
  const _ActivitiesTable({
    required this.activities,
    required this.statusLabel,
    required this.approvalLabel,
  });

  final List<ProjectActivity> activities;
  final String Function(ProjectActivityStatus) statusLabel;
  final String Function(ProjectApprovalStatus) approvalLabel;

  @override
  Widget build(BuildContext context) {
    const indexWidth = 48.0;
    const activityWidth = 220.0;
    const descriptionWidth = 320.0;
    const phaseWidth = 150.0;
    const disciplineWidth = 150.0;
    const roleWidth = 160.0;
    const assignedToWidth = 160.0;
    const statusWidth = 120.0;
    const approvalWidth = 110.0;
    const sourceWidth = 170.0;
    const appliesToWidth = 230.0;
    const updatedWidth = 110.0;

    if (activities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Text(
          'No activities found for the selected filters.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minTableWidth = 1850.0;
          final tableWidth = constraints.maxWidth < minTableWidth
              ? minTableWidth
              : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: DataTable(
                horizontalMargin: 12,
                columnSpacing: 16,
                showBottomBorder: true,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 68,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFF374151),
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF111827),
                ),
                columns: [
                  DataColumn(label: _header('#', indexWidth)),
                  DataColumn(label: _header('Activity', activityWidth)),
                  DataColumn(label: _header('Description', descriptionWidth)),
                  DataColumn(label: _header('Phase', phaseWidth)),
                  DataColumn(label: _header('Discipline', disciplineWidth)),
                  DataColumn(label: _header('Role', roleWidth)),
                  DataColumn(label: _header('Assigned To', assignedToWidth)),
                  DataColumn(label: _header('Status', statusWidth)),
                  DataColumn(label: _header('Approval', approvalWidth)),
                  DataColumn(label: _header('Source', sourceWidth)),
                  DataColumn(label: _header('Applies To', appliesToWidth)),
                  DataColumn(label: _header('Updated', updatedWidth)),
                ],
                rows: activities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;
                  final assignedTo = (activity.assignedTo ?? '').trim();
                  final phase = activity.phase.trim().isEmpty
                      ? 'Unspecified'
                      : activity.phase;
                  final source = activity.sourceSection.replaceAll('_', ' ');
                  final appliesTo = activity.applicableSections.isEmpty
                      ? '-'
                      : activity.applicableSections.join(', ');
                  return DataRow.byIndex(
                    index: index,
                    color: WidgetStateProperty.resolveWith<Color?>(
                      (states) => index.isEven
                          ? const Color(0xFFFAFBFF)
                          : Colors.transparent,
                    ),
                    cells: [
                      DataCell(_cell('${index + 1}', width: indexWidth)),
                      DataCell(_cell(activity.title, width: activityWidth)),
                      DataCell(
                          _cell(activity.description, width: descriptionWidth)),
                      DataCell(_cell(phase, width: phaseWidth)),
                      DataCell(
                          _cell(activity.discipline, width: disciplineWidth)),
                      DataCell(_cell(activity.role, width: roleWidth)),
                      DataCell(_cell(assignedTo.isEmpty ? '-' : assignedTo,
                          width: assignedToWidth)),
                      DataCell(_statusPill(statusLabel(activity.status))),
                      DataCell(_approvalPill(
                          approvalLabel(activity.approvalStatus))),
                      DataCell(_cell(source, width: sourceWidth)),
                      DataCell(_cell(appliesTo, width: appliesToWidth)),
                      DataCell(_cell(_formatDate(activity.updatedAt),
                          width: updatedWidth)),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _cell(String value, {required double width}) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _statusPill(String label) {
    Color bg;
    Color fg;
    switch (label) {
      case 'Implemented':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 'Acknowledged':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        break;
      case 'Rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      case 'Deferred':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFF9A3412);
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _approvalPill(String label) {
    Color bg;
    Color fg;
    switch (label) {
      case 'Approved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'Locked':
        bg = const Color(0xFFE5E7EB);
        fg = const Color(0xFF1F2937);
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF4B5563);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
