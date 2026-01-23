import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/screens/technical_alignment_screen.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class RequirementsImplementationScreen extends StatefulWidget {
  const RequirementsImplementationScreen({super.key});

  @override
  State<RequirementsImplementationScreen> createState() => _RequirementsImplementationScreenState();
}

class _RequirementsImplementationScreenState extends State<RequirementsImplementationScreen> {
  final TextEditingController _notesController = TextEditingController();

  final List<_RequirementRow> _requirementRows = [
    _RequirementRow(
      title: 'User journeys',
      owner: 'Product',
      definition: 'Epic to story map locked, acceptance criteria captured.',
    ),
    _RequirementRow(
      title: 'System behaviors',
      owner: 'Engineering',
      definition: 'Functional and non-functional requirements approved.',
    ),
    _RequirementRow(
      title: 'Integration points',
      owner: 'Platform',
      definition: 'Contracts, payloads, and error handling documented.',
    ),
  ];

  // Checklist items with status
  final List<_ChecklistItem> _checklistItems = [
    _ChecklistItem(
      title: 'Key flows covered',
      description: 'All priority user journeys have mapped requirements.',
      status: ChecklistStatus.ready,
    ),
    _ChecklistItem(
      title: 'Constraints documented',
      description: 'Performance, security, and compliance captured.',
      status: ChecklistStatus.inReview,
    ),
    _ChecklistItem(
      title: 'Stakeholder sign-off',
      description: 'Product, design, and engineering alignment.',
      status: ChecklistStatus.pending,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final pid = provider?.projectData.projectId;
      if (pid != null && pid.isNotEmpty) {
        await ProjectNavigationService.instance.saveLastPage(pid, 'requirements-implementation');
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _navigateToDesignOverview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DesignPhaseScreen()),
    );
  }

  void _navigateToTechnicalAlignment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TechnicalAlignmentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 16.0 : 40.0;
    final ownerOptions = _ownerOptions();

    return ResponsiveScaffold(
      activeItemLabel: 'Requirements Implementation',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Design',
            showImportButton: false,
            showContentButton: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main content area
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section label
                        Text(
                          'REQUIREMENTS IMPLEMENTATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Main heading
                        const Text(
                          'Translate agreed design scope into clear, actionable requirements',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1D1F),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Description
                        Text(
                          'Break down the approved design intent into user stories, functional requirements, and constraints that downstream teams can build against.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Next in flow banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Next in flow: Technical alignment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Notes input field
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4E7EC)),
                          ),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 2,
                            style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Capture key implementation notes here... (priorities, story mapping decisions, sequencing, and non-negotiables)',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keep this focused on what implementation teams must understand before estimating and building.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRequirementsBreakdownCard(ownerOptions),
                            const SizedBox(height: 24),
                            _buildReadinessChecklistCard(ownerOptions),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: Design overview',
                    nextLabel: 'Next: Technical alignment',
                    onBack: _navigateToDesignOverview,
                    onNext: _navigateToTechnicalAlignment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsBreakdownCard(List<String> ownerOptions) {
    final rowCount = _requirementRows.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionIcon(Icons.view_list_rounded, const Color(0xFF1D4ED8)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requirements breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'World-class requirements ledger for implementation-ready scope.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _requirementRows.add(
                      _RequirementRow(
                        title: 'New requirement',
                        owner: 'Owner',
                        definition: 'Define acceptance criteria and evidence.',
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add row'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D4ED8),
                  side: const BorderSide(color: Color(0xFFD6DCE8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Requirement group', flex: 3),
              _TableColumn(label: 'Owner', flex: 2),
              _TableColumn(label: 'Definition of ready', flex: 4),
              _TableColumn(label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < rowCount; i++) ...[
            _buildRequirementRow(
              _requirementRows[i],
              index: i,
              isStriped: i.isOdd,
              ownerOptions: ownerOptions,
            ),
            if (i != rowCount - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _requirementRows.add(
                      _RequirementRow(
                        title: 'New requirement',
                        owner: 'Owner',
                        definition: 'Define acceptance criteria and evidence.',
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add requirement row'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1D1F),
                  side: const BorderSide(color: Color(0xFFD6DCE8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: const Text('Import from design'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessChecklistCard(List<String> ownerOptions) {
    final rowCount = _checklistItems.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionIcon(Icons.fact_check_outlined, const Color(0xFF16A34A)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Readiness checklist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Exceptional readiness table for confident technical alignment.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _checklistItems.add(
                      _ChecklistItem(
                        title: 'New checklist item',
                        description: 'Describe the evidence required.',
                        status: ChecklistStatus.pending,
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add item'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16A34A),
                  side: const BorderSide(color: Color(0xFFD6DCE8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Checklist item', flex: 4),
              _TableColumn(label: 'Owner', flex: 2),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < rowCount; i++) ...[
            _buildChecklistRow(
              _checklistItems[i],
              index: i,
              isStriped: i.isOdd,
              ownerOptions: ownerOptions,
            ),
            if (i != rowCount - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          Text(
            'Implementation notes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            decoration: InputDecoration(
              hintText: 'Capture sequencing decisions, launch scope, and deferred items.',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save notes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1D1F),
                side: const BorderSide(color: Color(0xFFD6DCE8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionIcon(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildTableHeaderRow({required List<_TableColumn> columns}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Align(
                alignment: column.alignment,
                child: Text(
                  column.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(
    _RequirementRow row, {
    required int index,
    required bool isStriped,
    required List<String> ownerOptions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriped ? const Color(0xFFF9FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildTableField(
              initialValue: row.title,
              hintText: 'Requirement group',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildOwnerDropdown(
              value: row.owner,
              options: ownerOptions,
              onChanged: (value) {
                setState(() => _requirementRows[index].owner = value);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: _buildTableField(
              initialValue: row.definition,
              hintText: 'Definition of ready',
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmDelete('requirement');
                  if (!confirmed) return;
                  setState(() => _requirementRows.removeAt(index));
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(
    _ChecklistItem item, {
    required int index,
    required bool isStriped,
    required List<String> ownerOptions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriped ? const Color(0xFFF9FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableField(
                  initialValue: item.title,
                  hintText: 'Checklist item',
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildOwnerDropdown(
              value: item.owner ?? '',
              options: ownerOptions,
              onChanged: (value) {
                setState(() => _checklistItems[index].owner = value);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<ChecklistStatus>(
              initialValue: item.status,
              alignment: Alignment.center,
              isExpanded: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              selectedItemBuilder: (context) => ChecklistStatus.values
                  .map(
                    (status) => Align(
                      alignment: Alignment.center,
                      child:
                          Text(_statusLabel(status), textAlign: TextAlign.center),
                    ),
                  )
                  .toList(),
              items: ChecklistStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Center(
                        child:
                            Text(_statusLabel(status), textAlign: TextAlign.center),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _checklistItems[index].status = value);
              },
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmDelete('checklist item');
                  if (!confirmed) return;
                  setState(() => _checklistItems.removeAt(index));
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableField({
    required String initialValue,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
        ),
      ),
    );
  }

  List<String> _ownerOptions() {
    final provider = ProjectDataInherited.maybeOf(context);
    final members = provider?.projectData.teamMembers ?? [];
    final names = members
        .map((member) => member.name.trim().isNotEmpty ? member.name.trim() : member.email.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (names.isEmpty) return const ['Owner'];
    return names.toSet().toList();
  }

  Widget _buildOwnerDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final normalized = value.trim();
    final items = normalized.isEmpty || options.contains(normalized)
        ? options
        : [normalized, ...options];
    return DropdownButtonFormField<String>(
      initialValue: items.first,
      alignment: Alignment.center,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      selectedItemBuilder: (context) => items
          .map((owner) => Align(
                alignment: Alignment.center,
                child: Text(owner, textAlign: TextAlign.center),
              ))
          .toList(),
      items: items
          .map((owner) => DropdownMenuItem(
                value: owner,
                child: Center(child: Text(owner, textAlign: TextAlign.center)),
              ))
          .toList(),
      onChanged: (newValue) {
        if (newValue == null) return;
        onChanged(newValue);
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete row?'),
        content: Text('Remove this $label from the table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  String _statusLabel(ChecklistStatus status) {
    switch (status) {
      case ChecklistStatus.ready:
        return 'Ready';
      case ChecklistStatus.inReview:
        return 'In review';
      case ChecklistStatus.pending:
        return 'Pending';
    }
  }

  Widget _buildStatusBadge(ChecklistStatus status) {
    Color bgColor;
    Color textColor;
    String label;
    bool showDot = false;

    switch (status) {
      case ChecklistStatus.ready:
        bgColor = Colors.transparent;
        textColor = const Color(0xFF22C55E);
        label = 'Ready';
        showDot = true;
        break;
      case ChecklistStatus.inReview:
        bgColor = Colors.transparent;
        textColor = const Color(0xFF6B7280);
        label = 'In review';
        break;
      case ChecklistStatus.pending:
        bgColor = Colors.transparent;
        textColor = const Color(0xFF6B7280);
        label = 'Pending';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDot) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

}

enum ChecklistStatus { ready, inReview, pending }

class _TableColumn {
  const _TableColumn({
    required this.label,
    this.flex = 1,
    this.alignment = Alignment.center,
  });

  final String label;
  final int flex;
  final Alignment alignment;
}

class _RequirementRow {
  _RequirementRow({
    required this.title,
    required this.owner,
    required this.definition,
  });

  String title;
  String owner;
  String definition;
}

class _ChecklistItem {
  final String title;
  final String description;
  ChecklistStatus status;
  String? owner;

  _ChecklistItem({
    required this.title,
    required this.description,
    required this.status,
  });
}
