import 'package:flutter/material.dart';

import 'package:ndu_project/utils/csv_import_helper.dart';
import 'package:ndu_project/widgets/csv_import_dialog.dart';
import 'package:ndu_project/widgets/voice_text_field.dart';
const double _defaultColumnWidth = 160;
const double _tableHorizontalPadding = 20;
const double _columnGap = 12;
const double _actionColumnWidth = 80;

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

class _EditingMode extends InheritedWidget {
  final bool isEditing;

  const _EditingMode({
    required this.isEditing,
    required super.child,
  });

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_EditingMode>()
            ?.isEditing ??
        false;
  }

  @override
  bool updateShouldNotify(_EditingMode oldWidget) =>
      isEditing != oldWidget.isEditing;
}

enum LaunchFieldType { text, date, dropdown }

class LaunchColumn {
  final String label;
  final double? width;
  final bool flexible;
  final LaunchFieldType fieldType;
  final List<String>? dropdownItems;
  final String? hint;

  const LaunchColumn({
    required this.label,
    this.width,
    this.flexible = false,
    this.fieldType = LaunchFieldType.text,
    this.dropdownItems,
    this.hint,
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
    this.onAddValues,
    this.addLabel = 'Add item',
    this.importLabel,
    this.onImport,
    this.csvColumns,
    this.onCsvImport,
    this.emptyMessage = 'No entries yet. Add details to get started.',
  }) : _columns = columns
            .map((c) => c is LaunchColumn
                ? c
                : LaunchColumn(label: c.toString(), flexible: true))
            .toList();

  final String title;
  final String? subtitle;
  final List<LaunchColumn> _columns;
  final int rowCount;
  final Widget Function(BuildContext context, int rowIdx) cellBuilder;
  final VoidCallback? onAdd;
  final ValueChanged<Map<String, String>>? onAddValues;
  final String addLabel;
  final String? importLabel;
  final VoidCallback? onImport;

  /// CSV import column specifications — enables the "Import CSV" button
  final List<CsvColumnSpec>? csvColumns;

  /// Callback when CSV rows are imported
  final ValueChanged<List<Map<String, String>>>? onCsvImport;

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
          _buildCardHeader(context),
          if (rowCount == 0)
            _buildEmpty()
          else
            _buildRows(context),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
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
          if (csvColumns != null && onCsvImport != null) ...[
            OutlinedButton.icon(
              onPressed: () => _showCsvImportDialog(context),
              icon: const Icon(Icons.upload_file_outlined, size: 16),
              label: const Text('Import CSV'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF93C5FD)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (onImport != null && importLabel != null) ...[
            OutlinedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.download_outlined, size: 16),
              label: Text(importLabel!),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                foregroundColor: const Color(0xFF4B5563),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (onAdd != null || onAddValues != null)
            OutlinedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add, size: 16, color: Color(0xFF6B7280)),
              label: Text(
                addLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: Color(0xFF374151),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                backgroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCsvImportDialog(BuildContext context) async {
    if (csvColumns == null || onCsvImport == null) return;
    final result = await showCsvImportDialog(
      context,
      tableTitle: title,
      columns: csvColumns!,
    );
    if (result != null && result.isNotEmpty) {
      onCsvImport!(result);
    }
  }

  Future<void> _showAddDialog(BuildContext context) async {
    if (onAddValues != null) {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (ctx) => _AddItemDialog(
          title: title,
          columns: _columns,
        ),
      );
      if (result != null) onAddValues!(result);
    } else {
      onAdd?.call();
    }
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
          (row) => row is LaunchDataRow && (row.onDelete != null || row.onEdit != null),
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
                for (int i = 0; i < rows.length; i++) ...[
                  rows[i],
                  if (i < rows.length - 1)
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                ],
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
        color: Color(0xFF1E293B),
      ),
      child: Row(
        children: [
          ..._buildColumnSlots(
            columns,
            (col, _) => Text(
              col.label.toUpperCase(),
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFFFFF),
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (hasRowActions)
            SizedBox(
              width: _actionColumnWidth,
              child: const Text(
                'ACTIONS',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFFFFF),
                  letterSpacing: 0.5,
                ),
              ),
            ),
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
    this.onEdit,
    this.showDivider = false,
  });

  final List<Widget> cells;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool showDivider;

  @override
  State<LaunchDataRow> createState() => _LaunchDataRowState();
}

class _LaunchDataRowState extends State<LaunchDataRow> {
  bool _hovering = false;
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final tableLayout = _TableLayoutInherited.of(context);
    final columns = tableLayout?.columns;
    final hasActions = widget.onDelete != null || widget.onEdit != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Column(
        children: [
          Container(
            width: tableLayout?.tableWidth,
            decoration: BoxDecoration(
              color: _isEditing
                  ? const Color(0xFFFFFDF5)
                  : (_hovering ? const Color(0xFFF8FAFC) : Colors.white),
              border: _isEditing
                  ? const Border(
                      left: BorderSide(color: Color(0xFFF59E0B), width: 3))
                  : null,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: _tableHorizontalPadding,
              vertical: 10,
            ),
            child: _EditingMode(
              isEditing: _isEditing,
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
                  if (hasActions)
                    SizedBox(
                      width: _actionColumnWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (widget.onEdit != null)
                            Tooltip(
                              message: _isEditing ? 'Save' : 'Edit',
                              child: IconButton(
                                icon: Icon(
                                  _isEditing
                                      ? Icons.check_circle_rounded
                                      : Icons.edit_outlined,
                                  size: 16,
                                  color: _isEditing
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF9CA3AF),
                                ),
                                onPressed: () {
                                  setState(() => _isEditing = !_isEditing);
                                },
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                                splashRadius: 14,
                              ),
                            ),
                          if (widget.onEdit != null && widget.onDelete != null)
                            const SizedBox(width: 2),
                          if (widget.onDelete != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 16, color: Color(0xFFEF4444)),
                              onPressed: widget.onDelete,
                              tooltip: 'Delete',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              splashRadius: 14,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.showDivider)
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
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
      height: 38,
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

/// A styled editable cell that renders as a proper input field
/// with a subtle border, rounded corners, and background fill
/// — matching the checklist table style from the screenshot.
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
  bool _isFocused = false;

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
    final isEditing = _EditingMode.of(context);

    if (!isEditing) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          widget.value.isEmpty ? '—' : widget.value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: widget.value.isEmpty
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF111827),
            fontWeight: widget.bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      );
    }

    final borderColor =
        _isFocused ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB);
    final bgColor = _isFocused ? Colors.white : const Color(0xFFF9FAFB);

    final child = Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1),
        ),
        child: VoiceTextField(
          controller: _controller,
          onChanged: widget.onChanged,
          style: TextStyle(
            fontSize: 12.5,
            color: const Color(0xFF111827),
            fontWeight: widget.bold ? FontWeight.w600 : FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            isDense: true,
          ),
        ),
      ),
    );
    final inTable = _TableLayoutInherited.of(context) != null;
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
  bool _isHovering = false;

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
    final isEditing = _EditingMode.of(context);

    if (!isEditing) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEmpty) ...[
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
            ],
            Text(
              isEmpty ? '—' : text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isEmpty
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: 38,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pickDate(context),
          child: Container(
            decoration: BoxDecoration(
              color: _isHovering ? Colors.white : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovering
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE5E7EB),
                width: _isHovering ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEmpty ? widget.hint : text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isEmpty
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
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
    final isEditing = _EditingMode.of(context);

    if (!isEditing) {
      final label = effective ?? 'Not set';
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      );
    }

    if (menuItems.isEmpty || effective == null) {
      return SizedBox(
        width: width,
        height: 38,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              'Not set',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: 38,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effective,
              isDense: true,
              isExpanded: true,
              iconSize: 14,
              iconDisabledColor: statusColor.withOpacity(0.5),
              iconEnabledColor: statusColor,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
    if (s.contains('complet') || s.contains('done') || s.contains('closed') || s.contains('ready')) {
      return const Color(0xFF10B981);
    }
    if (s.contains('progress') || s.contains('active') || s.contains('track')) {
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

class _AddItemDialog extends StatefulWidget {
  final String title;
  final List<LaunchColumn> columns;

  const _AddItemDialog({
    required this.title,
    required this.columns,
  });

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _dateValues = <String, String>{};
  final _dropdownValues = <String, String?>{};

  @override
  void initState() {
    super.initState();
    for (final col in widget.columns) {
      switch (col.fieldType) {
        case LaunchFieldType.text:
          _controllers[col.label] = TextEditingController();
        case LaunchFieldType.date:
          _dateValues[col.label] = '';
        case LaunchFieldType.dropdown:
          _dropdownValues[col.label] =
              (col.dropdownItems != null && col.dropdownItems!.isNotEmpty)
                  ? col.dropdownItems!.first
                  : null;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_circle_outline,
                color: Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add New Item',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20, color: Color(0xFF9CA3AF)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.columns
                .map((col) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildField(col),
                    ))
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Cancel',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('Add Item',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildField(LaunchColumn col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          col.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        _buildInput(col),
      ],
    );
  }

  Widget _buildInput(LaunchColumn col) {
    switch (col.fieldType) {
      case LaunchFieldType.text:
        return TextFormField(
          controller: _controllers[col.label],
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: col.hint ?? 'Enter ${col.label.toLowerCase()}',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
          ),
        );
      case LaunchFieldType.date:
        return _buildDateField(col);
      case LaunchFieldType.dropdown:
        return _buildDropdownField(col);
    }
  }

  Widget _buildDateField(LaunchColumn col) {
    final value = _dateValues[col.label] ?? '';
    final display = value.isEmpty ? '' : value;
    return InkWell(
      onTap: () => _pickDate(col.label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: display.isEmpty
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFF2563EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                display.isEmpty
                    ? (col.hint ?? 'Select date')
                    : display,
                style: TextStyle(
                  fontSize: 13,
                  color: display.isEmpty
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF111827),
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(String label) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (selected == null) return;
    final formatted =
        '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    setState(() => _dateValues[label] = formatted);
  }

  Widget _buildDropdownField(LaunchColumn col) {
    final items = col.dropdownItems ?? [];
    final current = _dropdownValues[col.label];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          hint: Text(col.hint ?? 'Select ${col.label.toLowerCase()}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          iconSize: 18,
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          items: items
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _dropdownValues[col.label] = v),
        ),
      ),
    );
  }

  void _submit() {
    final values = <String, String>{};
    for (final col in widget.columns) {
      switch (col.fieldType) {
        case LaunchFieldType.text:
          values[col.label] = _controllers[col.label]?.text ?? '';
        case LaunchFieldType.date:
          values[col.label] = _dateValues[col.label] ?? '';
        case LaunchFieldType.dropdown:
          values[col.label] = _dropdownValues[col.label] ?? '';
      }
    }
    Navigator.pop(context, values);
  }
}