import 'package:flutter/material.dart';

const double _defaultColumnWidth = 160;
const double _tableHorizontalPadding = 20;
const double _columnGap = 2;
const double _actionColumnWidth = 40;

class _TableLayoutInherited extends InheritedWidget {
  final double tableWidth;
  final List<LaunchColumn> columns;
  final bool hasRowActions;

  const _TableLayoutInherited({
    required this.tableWidth,
    required this.columns,
    required this.hasRowActions,
    required super.child,
  });

  static _TableLayoutInherited? of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_TableLayoutInherited>();
    return inherited;
  }

  @override
  bool updateShouldNotify(_TableLayoutInherited oldWidget) =>
      tableWidth != oldWidget.tableWidth ||
      columns != oldWidget.columns ||
      hasRowActions != oldWidget.hasRowActions;
}

class LaunchColumn {
  final String label;
  final double? width;
  final bool flexible;

  const LaunchColumn({
    required this.label,
    this.width,
    this.flexible = false,
  }) : assert(
            width != null || flexible, 'Either width or flexible must be set');
}

class LaunchDataTable extends StatelessWidget {
  LaunchDataTable({
    super.key,
    required this.title,
    required List<dynamic> columns,
    required this.rowCount,
    required this.cellBuilder,
    this.subtitle,
    this.onAdd,
    this.addLabel = 'Add',
    this.importLabel,
    this.onImport,
    this.emptyMessage = 'No entries yet. Add details to get started.',
  }) : _columns = columns is List<LaunchColumn>
            ? columns
            : columns
                .map((c) => LaunchColumn(label: c.toString(), flexible: true))
                .toList();

  final String title;
  final String? subtitle;
  final List<LaunchColumn> _columns;
  final int rowCount;
  final Widget Function(BuildContext context, int rowIdx) cellBuilder;
  final VoidCallback? onAdd;
  final String addLabel;
  final String? importLabel;
  final VoidCallback? onImport;
  final String emptyMessage;

  List<LaunchColumn> get columns => _columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          if (rowCount == 0) _buildEmpty() else _buildRows(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onImport != null && importLabel != null) ...[
            OutlinedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.download_outlined, size: 16),
              label: Text(importLabel!),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                foregroundColor: const Color(0xFF4B5563),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (onAdd != null)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(addLabel),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                foregroundColor: const Color(0xFF2563EB),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF9CA3AF), size: 32),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
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

  Widget _buildRows(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = List.generate(rowCount, (i) => cellBuilder(context, i));
        final effectiveColumns = _resolveColumns(rows);
        final hasRowActions = rows.any(
          (row) => row is LaunchDataRow && row.onDelete != null,
        );
        final minTableWidth = _minTableWidth(effectiveColumns, hasRowActions);
        final tableWidth = constraints.maxWidth > minTableWidth
            ? constraints.maxWidth
            : minTableWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _TableLayoutInherited(
            tableWidth: tableWidth,
            columns: effectiveColumns,
            hasRowActions: hasRowActions,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumnHeaders(
                    tableWidth, effectiveColumns, hasRowActions),
                ...rows,
              ],
            ),
          ),
        );
      },
    );
  }

  List<LaunchColumn> _resolveColumns(List<Widget> rows) {
    return List.generate(columns.length, (index) {
      final column = columns[index];
      if (!column.flexible) return column;

      final widths = rows
          .whereType<LaunchDataRow>()
          .map((row) => index < row.cells.length ? row.cells[index] : null)
          .map(_fixedWidthForCell)
          .whereType<double>()
          .toList();

      if (widths.isEmpty) return column;

      return LaunchColumn(
        label: column.label,
        width: widths.reduce((a, b) => a > b ? a : b),
      );
    });
  }

  double? _fixedWidthForCell(Widget? cell) {
    if (cell is LaunchEditableCell && cell.width != null && !cell.expand) {
      return cell.width;
    }
    if (cell is LaunchDateCell) return cell.width;
    if (cell is LaunchStatusDropdown) return cell.width;
    return null;
  }

  double _minTableWidth(List<LaunchColumn> columns, bool hasRowActions) {
    final columnWidths = columns.fold<double>(0, (sum, col) {
      if (col.flexible) return sum + _defaultColumnWidth;
      return sum + (col.width ?? _defaultColumnWidth);
    });
    final gapWidth = columns.isEmpty ? 0 : _columnGap * (columns.length - 1);
    final rowPadding = _tableHorizontalPadding * 2;
    final actionWidth = hasRowActions ? _actionColumnWidth : 0.0;
    return columnWidths + gapWidth + rowPadding + actionWidth;
  }

  Widget _buildColumnHeaders(
    double tableWidth,
    List<LaunchColumn> columns,
    bool hasRowActions,
  ) {
    return Container(
      width: tableWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: _tableHorizontalPadding,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          ..._buildColumnSlots(
            columns,
            (col, _) => Text(
              col.label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (hasRowActions) const SizedBox(width: _actionColumnWidth),
        ],
      ),
    );
  }
}

List<Widget> _buildColumnSlots(
  List<LaunchColumn> columns,
  Widget Function(LaunchColumn column, int index) builder,
) {
  final slots = <Widget>[];
  for (var i = 0; i < columns.length; i++) {
    final column = columns[i];
    final child = builder(column, i);
    slots.add(
      column.flexible
          ? Expanded(child: child)
          : SizedBox(width: column.width, child: child),
    );
    if (i < columns.length - 1) {
      slots.add(const SizedBox(width: _columnGap));
    }
  }
  return slots;
}

class LaunchDataRow extends StatefulWidget {
  const LaunchDataRow({
    super.key,
    required this.cells,
    this.onDelete,
    this.showDivider = true,
  });

  final List<Widget> cells;
  final VoidCallback? onDelete;
  final bool showDivider;

  @override
  State<LaunchDataRow> createState() => _LaunchDataRowState();
}

class _LaunchDataRowState extends State<LaunchDataRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tableLayout = _TableLayoutInherited.of(context);
    final columns = tableLayout?.columns;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Column(
        children: [
          Container(
            width: tableLayout?.tableWidth,
            color: _hovering ? const Color(0xFFF9FAFB) : Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: _tableHorizontalPadding,
              vertical: 10,
            ),
            child: Row(
              children: [
                if (columns == null)
                  ...widget.cells
                else
                  ..._buildColumnSlots(
                    columns,
                    (_, index) {
                      if (index >= widget.cells.length) {
                        return const SizedBox.shrink();
                      }
                      return _CellSlot(child: widget.cells[index]);
                    },
                  ),
                if (tableLayout?.hasRowActions ?? false)
                  SizedBox(
                    width: _actionColumnWidth,
                    child: _hovering && widget.onDelete != null
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Color(0xFF9CA3AF)),
                            onPressed: widget.onDelete,
                            tooltip: 'Delete',
                          )
                        : null,
                  ),
              ],
            ),
          ),
          if (widget.showDivider)
            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
        ],
      ),
    );
  }
}

class _CellSlot extends StatelessWidget {
  const _CellSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

class LaunchEditableCell extends StatefulWidget {
  const LaunchEditableCell({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = '',
    this.width,
    this.bold = false,
    this.expand = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final double? width;
  final bool bold;
  final bool expand;

  @override
  State<LaunchEditableCell> createState() => _LaunchEditableCellState();
}

class _LaunchEditableCellState extends State<LaunchEditableCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant LaunchEditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text) return;

    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inTable = _TableLayoutInherited.of(context) != null;
    final child = TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: TextStyle(
        fontSize: 12,
        color: const Color(0xFF111827),
        fontWeight: widget.bold ? FontWeight.w600 : FontWeight.normal,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
      ),
    );
    if (inTable) return child;
    if (widget.width != null) {
      return SizedBox(width: widget.width, child: child);
    }
    if (widget.expand) return Expanded(child: child);
    return child;
  }
}

class LaunchDateCell extends StatefulWidget {
  const LaunchDateCell({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'Date',
    this.width = 120,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final double width;

  @override
  State<LaunchDateCell> createState() => _LaunchDateCellState();
}

class _LaunchDateCellState extends State<LaunchDateCell> {
  late String _displayValue;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant LaunchDateCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _displayValue) {
      _displayValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _displayValue.trim();
    final isEmpty = text.isEmpty;

    return SizedBox(
      width: widget.width,
      height: 34,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _pickDate(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isEmpty ? widget.hint : text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isEmpty
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _parseDate(_displayValue) ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );

    if (selected == null) return;

    final formatted = _formatDate(selected);
    setState(() => _displayValue = formatted);
    widget.onChanged(formatted);
  }

  DateTime? _parseDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    final parts = text.split(RegExp(r'[-/]'));
    if (parts.length != 3) return null;

    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) return null;

    if (parts[0].length == 4) return DateTime(first, second, third);
    if (parts[2].length == 4) return DateTime(third, second, first);
    return null;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class LaunchStatusDropdown extends StatelessWidget {
  const LaunchStatusDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 120,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final menuItems = _normalizedItems();
    final effective = _effectiveValue(menuItems);
    final statusColor = _statusColor(effective ?? '');

    if (menuItems.isEmpty || effective == null) {
      return SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Not set',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effective,
              isDense: true,
              isExpanded: true,
              iconSize: 14,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
              items: items
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          s,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  List<String> _normalizedItems() {
    final seen = <String>{};
    final normalized = <String>[];

    void addIfValid(String raw) {
      final item = raw.trim();
      if (item.isEmpty || !seen.add(item)) return;
      normalized.add(item);
    }

    for (final item in items) {
      addIfValid(item);
    }
    addIfValid(value);

    return normalized;
  }

  String? _effectiveValue(List<String> menuItems) {
    if (menuItems.isEmpty) return null;
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return menuItems.first;
    return menuItems.contains(trimmedValue) ? trimmedValue : menuItems.first;
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('complet') || s.contains('done') || s.contains('closed')) {
      return const Color(0xFF10B981);
    }
    if (s.contains('progress') || s.contains('active') || s.contains('in ')) {
      return const Color(0xFF2563EB);
    }
    if (s.contains('overdue') || s.contains('at risk') || s.contains('delay')) {
      return const Color(0xFFEF4444);
    }
    if (s.contains('pending') ||
        s.contains('review') ||
        s.contains('planned') ||
        s.contains('open')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF6B7280);
  }
}

Future<bool> launchConfirmDelete(BuildContext context,
    {String itemName = 'item'}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Entry',
          style:
              TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
      content: Text(
          'Are you sure you want to delete this $itemName? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
