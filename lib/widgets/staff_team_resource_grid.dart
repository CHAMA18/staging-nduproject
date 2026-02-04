import 'package:flutter/material.dart';
import 'package:ndu_project/models/staffing_row.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'dart:async';

/// Specialized Resource Grid widget for Staff Team Orchestration page
/// Features: Summary cards, AI suggestion pills, refined table with dynamic costing
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

  // Calculate summary metrics
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
        // Summary Cards
        _buildSummaryCards(),
        const SizedBox(height: 24),
        // AI Suggestions
        if (_aiSuggestions.isNotEmpty || _loadingSuggestions) ...[
          _buildAiSuggestions(),
          const SizedBox(height: 20),
        ],
        // Resource Grid Table
        _buildResourceGrid(),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
            child: _SummaryCard(
          title: 'Total Headcount',
          value: _totalHeadcount.toString(),
          icon: Icons.people_outline,
        )),
        const SizedBox(width: 16),
        Expanded(
            child: _SummaryCard(
          title: 'Total Personnel Investment',
          value: '\$${_totalInvestment.toStringAsFixed(0)}',
          icon: Icons.attach_money_outlined,
        )),
        const SizedBox(width: 16),
        Expanded(
            child: _SummaryCard(
          title: 'Staffing Split',
          value:
              '${_internalPercent.toStringAsFixed(0)}% Internal · ${_externalPercent.toStringAsFixed(0)}% External',
          icon: Icons.pie_chart_outline,
        )),
      ],
    );
  }

  Widget _buildAiSuggestions() {
    if (_loadingSuggestions) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const Text(
          'KAZ AI Suggestions:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        ..._aiSuggestions.map((role) => _SuggestionPill(
              role: role,
              onTap: () => _addSuggestion(role),
            )),
      ],
    );
  }

  Widget _buildResourceGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Staffing needs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addNewRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    foregroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          // Table
          if (_rows.isEmpty) _buildEmptyState() else _buildTable(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF9CA3AF), size: 32),
            const SizedBox(height: 12),
            const Text(
              'No entries yet. Add details to get started.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              _TableHeaderCell('Role', flex: 4),
              _TableHeaderCell('Qty', flex: 1),
              _TableHeaderCell('Type', flex: 2),
              _TableHeaderCell('Start Date', flex: 2),
              _TableHeaderCell('Duration', flex: 2),
              _TableHeaderCell('Monthly Cost', flex: 2),
              _TableHeaderCell('Subtotal', flex: 2),
              _TableHeaderCell('Status', flex: 2),
              _TableHeaderCell('Actions', flex: 1),
            ],
          ),
        ),
        // Table Rows
        ...List.generate(_rows.length, (index) {
          final row = _rows[index];
          final isLast = index == _rows.length - 1;
          return _StaffingRowWidget(
            row: row,
            onChanged: (updated) => _updateRow(index, updated),
            onDelete: () => _removeRow(index),
            showDivider: !isLast,
          );
        }),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF4338CA)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({
    required this.role,
    required this.onTap,
  });

  final String role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: Color(0xFF4338CA)),
            const SizedBox(width: 6),
            Text(
              role,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4338CA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.label, {required this.flex});

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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _StaffingRowWidget extends StatefulWidget {
  const _StaffingRowWidget({
    required this.row,
    required this.onChanged,
    required this.onDelete,
    required this.showDivider,
  });

  final StaffingRow row;
  final ValueChanged<StaffingRow> onChanged;
  final VoidCallback onDelete;
  final bool showDivider;

  @override
  State<_StaffingRowWidget> createState() => _StaffingRowWidgetState();
}

class _StaffingRowWidgetState extends State<_StaffingRowWidget> {
  late StaffingRow _row;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _row = widget.row;
  }

  @override
  void didUpdateWidget(_StaffingRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row != widget.row) {
      _row = widget.row;
    }
  }

  void _updateRow(StaffingRow updated) {
    setState(() => _row = updated);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        color: _isHovering ? const Color(0xFFF9FAFB) : Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: _EditableCell(
                      value: _row.role,
                      hint: 'Role / capability',
                      onChanged: (v) => _updateRow(_row.copyWith(role: v)),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: _EditableCell(
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
                      child: DropdownButton<bool>(
                        value: _row.isInternal,
                        isDense: true,
                        underline: const SizedBox(),
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
                  Expanded(
                    flex: 2,
                    child: _EditableCell(
                      value: _row.startDate,
                      hint: 'Start date',
                      onChanged: (v) => _updateRow(_row.copyWith(startDate: v)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _EditableCell(
                      value: _row.durationMonths,
                      hint: 'Months',
                      onChanged: (v) =>
                          _updateRow(_row.copyWith(durationMonths: v)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _EditableCell(
                      value: _row.monthlyCost,
                      hint: '\$0',
                      onChanged: (v) =>
                          _updateRow(_row.copyWith(monthlyCost: v)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _AnimatedSubtotal(value: _row.subtotalFormatted),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _row.status,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: _isHovering
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Color(0xFF9CA3AF)),
                              onPressed: widget.onDelete,
                              tooltip: 'Delete',
                            )
                          : const SizedBox(width: 40),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showDivider)
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ],
        ),
      ),
    );
  }
}

class _EditableCell extends StatelessWidget {
  const _EditableCell({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }
}

class _AnimatedSubtotal extends StatefulWidget {
  const _AnimatedSubtotal({required this.value});

  final String value;

  @override
  State<_AnimatedSubtotal> createState() => _AnimatedSubtotalState();
}

class _AnimatedSubtotalState extends State<_AnimatedSubtotal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedSubtotal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Text(
          widget.value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}
