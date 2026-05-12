import 'package:flutter/material.dart';
import 'package:ndu_project/models/staffing_row.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'dart:async';

class StaffTeamResourceGrid extends StatefulWidget {
  const StaffTeamResourceGrid({
    super.key,
    required this.rows,
    required this.onRowsChanged,
  });

  final List<StaffingRow> rows;
  final ValueChanged<List<StaffingRow>> onRowsChanged;

  @override
  State<StaffTeamResourceGrid> createState() => _StaffTeamResourceGridState();
}

class _StaffTeamResourceGridState extends State<StaffTeamResourceGrid> {
  List<StaffingRow> get _rows => widget.rows;
  List<String> _aiSuggestions = [];
  bool _loadingSuggestions = false;
  String? _suggestionError;

  @override
  void initState() {
    super.initState();
    _loadAiSuggestions();
  }

  Future<void> _loadAiSuggestions() async {
    setState(() {
      _loadingSuggestions = true;
      _suggestionError = null;
    });

    try {
      final data = ProjectDataHelper.getData(context);
      final contextText = ProjectDataHelper.buildExecutivePlanContext(
        data,
        sectionLabel: 'Staff Team Orchestration',
      );

      if (contextText.trim().isEmpty) {
        setState(() {
          _aiSuggestions = [];
          _loadingSuggestions = false;
        });
        return;
      }

      final ai = OpenAiServiceSecure();
      final suggestions = await ai.generateStaffingRoleSuggestions(
        context: contextText,
        maxSuggestions: 4,
      );

      if (mounted) {
        setState(() {
          _aiSuggestions = suggestions;
          _loadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestionError = e.toString();
          _loadingSuggestions = false;
          _aiSuggestions = [];
        });
      }
    }
  }

  void _addSuggestion(String roleName) {
    final newRow = StaffingRow(
      role: roleName,
      quantity: 1,
      isInternal: true,
      status: 'Not Started',
    );
    final updated = [..._rows, newRow];
    widget.onRowsChanged(updated);
  }

  void _addNewRow() {
    final newRow = StaffingRow(
      role: '',
      quantity: 1,
      isInternal: true,
      status: 'Not Started',
    );
    final updated = [..._rows, newRow];
    widget.onRowsChanged(updated);
  }

  void _updateRow(int index, StaffingRow updatedRow) {
    final updated = List<StaffingRow>.from(_rows);
    updated[index] = updatedRow;
    widget.onRowsChanged(updated);
  }

  void _removeRow(int index) {
    final updated = List<StaffingRow>.from(_rows);
    updated.removeAt(index);
    widget.onRowsChanged(updated);
  }

  int get _totalHeadcount => _rows.fold(0, (sum, row) => sum + row.quantity);
  double get _totalInvestment =>
      _rows.fold(0.0, (sum, row) => sum + row.subtotal);
  double get _internalHeadcount {
    return _rows
        .where((r) => r.isInternal)
        .fold(0, (sum, row) => sum + row.quantity)
        .toDouble();
  }

  double get _externalHeadcount {
    return _rows
        .where((r) => !r.isInternal)
        .fold(0, (sum, row) => sum + row.quantity)
        .toDouble();
  }

  double get _internalPercent {
    final total = _totalHeadcount;
    if (total == 0) return 0.0;
    return (_internalHeadcount / total) * 100;
  }

  double get _externalPercent {
    final total = _totalHeadcount;
    if (total == 0) return 0.0;
    return (_externalHeadcount / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 24),
        if (_aiSuggestions.isNotEmpty || _loadingSuggestions) ...[
          _buildAiSuggestions(),
          const SizedBox(height: 20),
        ],
        _buildResourceGrid(),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(builder: (context, constraints) {
      final useCompact = constraints.maxWidth < 680;
      if (useCompact) {
        return Column(
          children: [
            _PremiumSummaryCard(
              title: 'Total Headcount',
              value: _totalHeadcount.toString(),
              icon: Icons.people_outline_rounded,
              accentColor: const Color(0xFF4338CA),
              accentBg: const Color(0xFFEEF2FF),
            ),
            const SizedBox(height: 12),
            _PremiumSummaryCard(
              title: 'Total Investment',
              value: '\$${_totalInvestment.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: const Color(0xFF059669),
              accentBg: const Color(0xFFECFDF5),
            ),
            const SizedBox(height: 12),
            _PremiumSummaryCard(
              title: 'Staffing Mix',
              value:
                  '${_internalPercent.toStringAsFixed(0)}% Int · ${_externalPercent.toStringAsFixed(0)}% Ext',
              icon: Icons.pie_chart_outline_rounded,
              accentColor: const Color(0xFFD97706),
              accentBg: const Color(0xFFFEF3C7),
            ),
          ],
        );
      }

      return Row(
        children: [
          Expanded(
              child: _PremiumSummaryCard(
            title: 'Total Headcount',
            value: _totalHeadcount.toString(),
            icon: Icons.people_outline_rounded,
            accentColor: const Color(0xFF4338CA),
            accentBg: const Color(0xFFEEF2FF),
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _PremiumSummaryCard(
            title: 'Total Investment',
            value: '\$${_totalInvestment.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_outlined,
            accentColor: const Color(0xFF059669),
            accentBg: const Color(0xFFECFDF5),
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _PremiumSummaryCard(
            title: 'Staffing Mix',
            value:
                '${_internalPercent.toStringAsFixed(0)}% Int · ${_externalPercent.toStringAsFixed(0)}% Ext',
            icon: Icons.pie_chart_outline_rounded,
            accentColor: const Color(0xFFD97706),
            accentBg: const Color(0xFFFEF3C7),
          )),
        ],
      );
    });
  }

  Widget _buildAiSuggestions() {
    if (_loadingSuggestions) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Loading AI suggestions...',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    if (_suggestionError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFC107)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Could not load AI suggestions: $_suggestionError',
                style: const TextStyle(fontSize: 13, color: Color(0xFF856404)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'KAZ AI Suggestions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B21B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _aiSuggestions
                .map((role) => _PremiumSuggestionPill(
                      role: role,
                      onTap: () => _addSuggestion(role),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.table_chart_outlined,
                      size: 20, color: Color(0xFF4338CA)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staffing Needs',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Define roles, timelines, and costs for each resource',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _addNewRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Role'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          if (_rows.isEmpty)
            _buildEmptyState()
          else ...[
            _buildTableHeader(),
            ...List.generate(_rows.length, (index) {
              final row = _rows[index];
              final isLast = index == _rows.length - 1;
              return _PremiumStaffingRow(
                row: row,
                index: index,
                onChanged: (updated) => _updateRow(index, updated),
                onDelete: () => _removeRow(index),
                showDivider: !isLast,
              );
            }),
            _buildTableFooter(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded,
                  color: Color(0xFF9CA3AF), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'No staff roles defined yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add roles to build your resource plan, or use KAZ AI suggestions above.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: const Row(
        children: [
          _PremiumHeaderCell('Role', flex: 4),
          _PremiumHeaderCell('Qty', flex: 1),
          _PremiumHeaderCell('Type', flex: 2),
          _PremiumHeaderCell('Start Date', flex: 2),
          _PremiumHeaderCell('Duration', flex: 2),
          _PremiumHeaderCell('Monthly Cost', flex: 2),
          _PremiumHeaderCell('Subtotal', flex: 2),
          _PremiumHeaderCell('Status', flex: 2),
          _PremiumHeaderCell('', flex: 1),
        ],
      ),
    );
  }

  Widget _buildTableFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_rows.length} role${_rows.length == 1 ? '' : 's'} · $_totalHeadcount total headcount',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const Spacer(),
          Text(
            'Total Investment: \$${_totalInvestment.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSummaryCard extends StatelessWidget {
  const _PremiumSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.accentBg,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color accentBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSuggestionPill extends StatelessWidget {
  const _PremiumSuggestionPill({
    required this.role,
    required this.onTap,
  });

  final String role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC4B5FD)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              role,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B21B6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumHeaderCell extends StatelessWidget {
  const _PremiumHeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PremiumStaffingRow extends StatefulWidget {
  const _PremiumStaffingRow({
    required this.row,
    required this.index,
    required this.onChanged,
    required this.onDelete,
    required this.showDivider,
  });

  final StaffingRow row;
  final int index;
  final ValueChanged<StaffingRow> onChanged;
  final VoidCallback onDelete;
  final bool showDivider;

  @override
  State<_PremiumStaffingRow> createState() => _PremiumStaffingRowState();
}

class _PremiumStaffingRowState extends State<_PremiumStaffingRow> {
  late StaffingRow _row;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _row = widget.row;
  }

  @override
  void didUpdateWidget(_PremiumStaffingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row != widget.row) {
      _row = widget.row;
    }
  }

  void _updateRow(StaffingRow updated) {
    setState(() => _row = updated);
    widget.onChanged(updated);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return const Color(0xFF059669);
      case 'in progress':
      case 'active':
        return const Color(0xFF2563EB);
      case 'planned':
      case 'not started':
        return const Color(0xFF6B7280);
      case 'open':
      case 'at risk':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF4338CA);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return const Color(0xFFECFDF5);
      case 'in progress':
      case 'active':
        return const Color(0xFFEFF6FF);
      case 'planned':
      case 'not started':
        return const Color(0xFFF3F4F6);
      case 'open':
      case 'at risk':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFEEF2FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) =>
          Future.microtask(() => setState(() => _isHovering = true)),
      onExit: (_) =>
          Future.microtask(() => setState(() => _isHovering = false)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _isHovering ? const Color(0xFFF8FAFC) : Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: _PremiumEditableCell(
                      value: _row.role,
                      hint: 'Role / capability',
                      onChanged: (v) => _updateRow(_row.copyWith(role: v)),
                      align: TextAlign.left,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: _PremiumEditableCell(
                      value: _row.quantity.toString(),
                      hint: '1',
                      onChanged: (v) {
                        final qty = int.tryParse(v) ?? 1;
                        _updateRow(_row.copyWith(quantity: qty));
                      },
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _row.isInternal
                              ? const Color(0xFFEEF2FF)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _row.isInternal
                                ? const Color(0xFFC7D2FE)
                                : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: DropdownButton<bool>(
                          value: _row.isInternal,
                          isDense: true,
                          underline: const SizedBox(),
                          iconSize: 14,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _row.isInternal
                                ? const Color(0xFF4338CA)
                                : const Color(0xFF92400E),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: true,
                                child: Text('Internal',
                                    style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(
                                value: false,
                                child: Text('External',
                                    style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (v) => v != null
                              ? _updateRow(_row.copyWith(isInternal: v))
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _PremiumEditableCell(
                      value: _row.startDate,
                      hint: 'Start date',
                      onChanged: (v) =>
                          _updateRow(_row.copyWith(startDate: v)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _PremiumEditableCell(
                      value: _row.durationMonths,
                      hint: 'Months',
                      onChanged: (v) =>
                          _updateRow(_row.copyWith(durationMonths: v)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _PremiumEditableCell(
                      value: _row.monthlyCost,
                      hint: '\$0',
                      onChanged: (v) =>
                          _updateRow(_row.copyWith(monthlyCost: v)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                        child: Text(_row.subtotalFormatted),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusBg(_row.status),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _statusColor(_row.status).withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          _row.status,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(_row.status),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: _isHovering
                          ? Material(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: widget.onDelete,
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.delete_outline_rounded,
                                      size: 16, color: Color(0xFFDC2626)),
                                ),
                              ),
                            )
                          : const SizedBox(width: 40),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showDivider)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ],
        ),
      ),
    );
  }
}

class _PremiumEditableCell extends StatelessWidget {
  const _PremiumEditableCell({
    required this.value,
    required this.hint,
    required this.onChanged,
    this.align = TextAlign.center,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
      textAlign: align,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9CA3AF),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        isDense: true,
      ),
    );
  }
}
