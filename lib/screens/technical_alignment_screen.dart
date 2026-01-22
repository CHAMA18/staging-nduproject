import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/development_set_up_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/theme.dart';

class TechnicalAlignmentScreen extends StatefulWidget {
  const TechnicalAlignmentScreen({super.key});

  @override
  State<TechnicalAlignmentScreen> createState() => _TechnicalAlignmentScreenState();
}

class _TechnicalAlignmentScreenState extends State<TechnicalAlignmentScreen> {
  final TextEditingController _notesController = TextEditingController();

  final List<_ConstraintRow> _constraints = [
    _ConstraintRow(
      constraint: 'Platform & stack boundaries',
      guardrail: 'Approved languages, frameworks, hosting, and security baselines.',
      owner: 'Platform',
      status: 'In review',
    ),
    _ConstraintRow(
      constraint: 'Regulatory & compliance',
      guardrail: 'Industry regulations (PCI, HIPAA, GDPR) and required controls.',
      owner: 'Security',
      status: 'Aligned',
    ),
    _ConstraintRow(
      constraint: 'Performance & scale targets',
      guardrail: 'Expected users, peak load, latency targets, and data growth assumptions.',
      owner: 'Engineering',
      status: 'Draft',
    ),
  ];

  final List<_RequirementMappingRow> _mappings = [
    _RequirementMappingRow(
      requirement: 'Account lifecycle & access',
      approach: 'Central auth service, scoped tokens, standardized role model.',
      status: 'Aligned',
    ),
    _RequirementMappingRow(
      requirement: 'Data residency & privacy',
      approach: 'Regional data stores, encryption at rest/in transit, retention policies.',
      status: 'In review',
    ),
    _RequirementMappingRow(
      requirement: 'Operational visibility',
      approach: 'Unified logging, metrics, tracing, and alerting across services.',
      status: 'Draft',
    ),
  ];

  final List<_DependencyDecisionRow> _dependencies = [
    _DependencyDecisionRow(
      item: 'External systems & contracts',
      detail: 'Which vendors, APIs, or internal platforms this work depends on.',
      owner: 'Integration',
      status: 'Pending',
    ),
    _DependencyDecisionRow(
      item: 'Critical technical decisions',
      detail: 'Architectural choices the team must agree on before implementation.',
      owner: 'Architecture',
      status: 'In review',
    ),
    _DependencyDecisionRow(
      item: 'Risks & mitigation options',
      detail: 'Where the design might fail and how you plan to reduce impact.',
      owner: 'Engineering',
      status: 'Draft',
    ),
  ];

  final List<String> _statusOptions = const ['Aligned', 'In review', 'Draft', 'Pending'];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);
    final ownerOptions = _ownerOptions();

    return ResponsiveScaffold(
      activeItemLabel: 'Technical Alignment',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Design Phase',
            showImportButton: false,
            showContentButton: false,
            showNavigationButtons: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  Text(
                    'Technical Alignment',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: LightModeColors.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Align requirements with architecture, constraints, and standards',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture the minimum set of technical decisions so the team can move forward confidently without over engineering or rework.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),

                  // Notes Input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppSemanticColors.border),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        hintText: 'Input your notes here 9 (key constraints, assumptions, dependencies, and open technical questions)',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Helper Text
                  Text(
                    'Keep this focused: capture only exceptional, world-class decisions that impact scope, sequencing, or cross-team coordination.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConstraintsCard(ownerOptions),
                      const SizedBox(height: 20),
                      _buildRequirementMappingCard(),
                      const SizedBox(height: 20),
                      _buildDependenciesCard(ownerOptions),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Bottom Navigation
                  _buildBottomNavigation(isMobile),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: LightModeColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Document decisions at the level of contracts and constraints. Detailed implementation choices can live with engineering once the direction is clear.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConstraintsCard(List<String> ownerOptions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
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
          _buildSectionHeader(
            icon: Icons.policy_outlined,
            color: const Color(0xFF1D4ED8),
            title: 'Constraints & guardrails',
            subtitle: 'World-class guardrails that clarify what must never drift.',
            actionLabel: 'Add constraint',
            onAction: () {
              setState(() {
                _constraints.add(
                  _ConstraintRow(
                    constraint: '',
                    guardrail: '',
                    owner: '',
                    status: 'Draft',
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Constraint', flex: 3),
              _TableColumn(label: 'Guardrail', flex: 5),
              _TableColumn(label: 'Owner', flex: 2),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          if (_constraints.isEmpty)
            _buildEmptyTableState(
              message: 'No constraints captured yet. Add the first guardrail.',
              actionLabel: 'Add constraint',
              onAction: () {
                setState(() {
                  _constraints.add(
                    _ConstraintRow(
                      constraint: '',
                      guardrail: '',
                      owner: '',
                      status: 'Draft',
                    ),
                  );
                });
              },
            )
          else
            for (int i = 0; i < _constraints.length; i++) ...[
              _buildConstraintRow(
                _constraints[i],
                index: i,
                isStriped: i.isOdd,
                ownerOptions: ownerOptions,
              ),
              if (i != _constraints.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildRequirementMappingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
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
          _buildSectionHeader(
            icon: Icons.swap_horiz_outlined,
            color: const Color(0xFF0F766E),
            title: 'Requirements → solution mapping',
            subtitle: 'Exceptional clarity on how requirements become technical choices.',
            actionLabel: 'Add mapping',
            onAction: () {
              setState(() {
                _mappings.add(
                  _RequirementMappingRow(
                    requirement: '',
                    approach: '',
                    status: 'Draft',
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Requirement', flex: 3),
              _TableColumn(label: 'Technical approach', flex: 5),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          if (_mappings.isEmpty)
            _buildEmptyTableState(
              message: 'No mappings yet. Add the first requirement-to-solution entry.',
              actionLabel: 'Add mapping',
              onAction: () {
                setState(() {
                  _mappings.add(
                    _RequirementMappingRow(
                      requirement: '',
                      approach: '',
                      status: 'Draft',
                    ),
                  );
                });
              },
            )
          else
            for (int i = 0; i < _mappings.length; i++) ...[
              _buildMappingRow(_mappings[i], index: i, isStriped: i.isOdd),
              if (i != _mappings.length - 1) const SizedBox(height: 8),
            ],
          const SizedBox(height: 16),
          Text(
            'Use this table to call out any requirement that needs a specific design pattern or infrastructure choice.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDependenciesCard(List<String> ownerOptions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
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
          _buildSectionHeader(
            icon: Icons.hub_outlined,
            color: const Color(0xFF9333EA),
            title: 'Dependencies & decisions',
            subtitle: 'World-class visibility into what must land before build.',
            actionLabel: 'Add dependency',
            onAction: () {
              setState(() {
                _dependencies.add(
                  _DependencyDecisionRow(
                    item: '',
                    detail: '',
                    owner: '',
                    status: 'Draft',
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Dependency or decision', flex: 4),
              _TableColumn(label: 'Detail', flex: 5),
              _TableColumn(label: 'Owner', flex: 2),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          if (_dependencies.isEmpty)
            _buildEmptyTableState(
              message: 'No dependencies yet. Add the first decision or external dependency.',
              actionLabel: 'Add dependency',
              onAction: () {
                setState(() {
                  _dependencies.add(
                    _DependencyDecisionRow(
                      item: '',
                      detail: '',
                      owner: '',
                      status: 'Draft',
                    ),
                  );
                });
              },
            )
          else
            for (int i = 0; i < _dependencies.length; i++) ...[
              _buildDependencyRow(
                _dependencies[i],
                index: i,
                isStriped: i.isOdd,
                ownerOptions: ownerOptions,
              ),
              if (i != _dependencies.length - 1) const SizedBox(height: 8),
            ],
          const SizedBox(height: 16),
          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exportAlignmentSummary,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export alignment summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAlignmentSummary() async {
    final doc = pw.Document();
    final notes = _notesController.text.trim();

    final constraints = _constraints
        .map((row) {
          final constraint = row.constraint.trim();
          final guardrail = row.guardrail.trim();
          final owner = row.owner.trim();
          final status = row.status.trim();
          if (constraint.isEmpty &&
              guardrail.isEmpty &&
              owner.isEmpty &&
              status.isEmpty) {
            return '';
          }
          final base = guardrail.isEmpty
              ? constraint
              : '$constraint — $guardrail';
          final ownerLabel = owner.isEmpty ? '' : 'Owner: $owner';
          final statusLabel = status.isEmpty ? '' : 'Status: $status';
          final meta = [ownerLabel, statusLabel]
              .where((value) => value.isNotEmpty)
              .join(' · ');
          return meta.isEmpty ? base : '$base ($meta)';
        })
        .where((line) => line.trim().isNotEmpty)
        .toList();

    final mappings = _mappings
        .map((row) {
          final requirement = row.requirement.trim();
          final approach = row.approach.trim();
          final status = row.status.trim();
          if (requirement.isEmpty && approach.isEmpty && status.isEmpty) {
            return '';
          }
          final base =
              approach.isEmpty ? requirement : '$requirement — $approach';
          return status.isEmpty ? base : '$base (Status: $status)';
        })
        .where((line) => line.trim().isNotEmpty)
        .toList();

    final dependencies = _dependencies
        .map((row) {
          final item = row.item.trim();
          final detail = row.detail.trim();
          final owner = row.owner.trim();
          final status = row.status.trim();
          if (item.isEmpty && detail.isEmpty && owner.isEmpty && status.isEmpty) {
            return '';
          }
          final base = detail.isEmpty ? item : '$item — $detail';
          final ownerLabel = owner.isEmpty ? '' : 'Owner: $owner';
          final statusLabel = status.isEmpty ? '' : 'Status: $status';
          final meta = [ownerLabel, statusLabel]
              .where((value) => value.isNotEmpty)
              .join(' · ');
          return meta.isEmpty ? base : '$base ($meta)';
        })
        .where((line) => line.trim().isNotEmpty)
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Technical Alignment Summary',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _pdfTextBlock('Notes', notes),
          _pdfSection('Constraints & guardrails', constraints),
          _pdfSection('Requirements → solution mapping', mappings),
          _pdfSection('Dependencies & decisions', dependencies),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'technical-alignment-summary.pdf',
    );
  }

  pw.Widget _pdfTextBlock(String title, String content) {
    final normalized = content.trim().isEmpty ? 'No entries.' : content.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(normalized, style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _pdfSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        if (items.isEmpty)
          pw.Text('No entries.', style: const pw.TextStyle(fontSize: 12))
        else
          pw.Column(
            children: items.map((item) => pw.Bullet(text: item)).toList(),
          ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add, size: 18),
          label: Text(actionLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: const BorderSide(color: Color(0xFFD6DCE8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Color(0xFF475467),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConstraintRow(
    _ConstraintRow row, {
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
              initialValue: row.constraint,
              hintText: 'Constraint',
              onChanged: (value) => row.constraint = value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _buildTableField(
              initialValue: row.guardrail,
              hintText: 'Guardrail',
              maxLines: 2,
              onChanged: (value) => row.guardrail = value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildOwnerDropdown(
              value: row.owner,
              options: ownerOptions,
              onChanged: (value) => row.owner = value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildStatusDropdown(
              value: row.status,
              onChanged: (value) => setState(() => _constraints[index].status = value),
              accent: const Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _buildDeleteAction(() async {
                final confirmed = await _confirmDelete('constraint');
                if (!confirmed) return;
                setState(() => _constraints.removeAt(index));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingRow(_RequirementMappingRow row, {required int index, required bool isStriped}) {
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
              initialValue: row.requirement,
              hintText: 'Requirement',
              onChanged: (value) => row.requirement = value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _buildTableField(
              initialValue: row.approach,
              hintText: 'Technical approach',
              maxLines: 2,
              onChanged: (value) => row.approach = value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildStatusDropdown(
              value: row.status,
              onChanged: (value) => setState(() => _mappings[index].status = value),
              accent: const Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _buildDeleteAction(() async {
                final confirmed = await _confirmDelete('mapping');
                if (!confirmed) return;
                setState(() => _mappings.removeAt(index));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDependencyRow(
    _DependencyDecisionRow row, {
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
            flex: 4,
            child: _buildTableField(
              initialValue: row.item,
              hintText: 'Dependency or decision',
              onChanged: (value) => row.item = value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _buildTableField(
              initialValue: row.detail,
              hintText: 'Detail',
              maxLines: 2,
              onChanged: (value) => row.detail = value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildOwnerDropdown(
              value: row.owner,
              options: ownerOptions,
              onChanged: (value) => row.owner = value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildStatusDropdown(
              value: row.status,
              onChanged: (value) => setState(() => _dependencies[index].status = value),
              accent: const Color(0xFF9333EA),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _buildDeleteAction(() async {
                final confirmed = await _confirmDelete('dependency');
                if (!confirmed) return;
                setState(() => _dependencies.removeAt(index));
              }),
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
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      minLines: 1,
      maxLines: null,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      onChanged: onChanged,
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

  Widget _buildStatusDropdown({
    required String value,
    required ValueChanged<String> onChanged,
    required Color accent,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      alignment: Alignment.center,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      selectedItemBuilder: (context) => _statusOptions
          .map((status) => Align(
                alignment: Alignment.center,
                child: Text(status, textAlign: TextAlign.center),
              ))
          .toList(),
      items: _statusOptions
          .map((status) => DropdownMenuItem(
                value: status,
                child: Center(child: Text(status, textAlign: TextAlign.center)),
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
          borderSide: BorderSide(color: accent, width: 2),
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

  Widget _buildDeleteAction(Future<void> Function() onDelete) {
    return TextButton.icon(
      onPressed: () async {
        await onDelete();
      },
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('Delete'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFB91C1C),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isMobile) {
    const accent = LightModeColors.lightPrimary;
    const onAccent = Colors.white;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back: Requirements implementation'),
            style: OutlinedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: onAccent,
              side: const BorderSide(color: accent),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DevelopmentSetUpScreen()),
            ),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Next: Development set up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back: Requirements implementation'),
          style: OutlinedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: onAccent,
            side: const BorderSide(color: accent),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Design phase · Technical alignment',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DevelopmentSetUpScreen()),
          ),
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Next: Development set up'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: onAccent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
        ),
      ],
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

  Widget _buildEmptyTableState({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1D1F),
              side: const BorderSide(color: Color(0xFFD6DCE8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

}

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

class _ConstraintRow {
  _ConstraintRow({
    required this.constraint,
    required this.guardrail,
    required this.owner,
    required this.status,
  });

  String constraint;
  String guardrail;
  String owner;
  String status;
}

class _RequirementMappingRow {
  _RequirementMappingRow({
    required this.requirement,
    required this.approach,
    required this.status,
  });

  String requirement;
  String approach;
  String status;
}

class _DependencyDecisionRow {
  _DependencyDecisionRow({
    required this.item,
    required this.detail,
    required this.owner,
    required this.status,
  });

  String item;
  String detail;
  String owner;
  String status;
}
