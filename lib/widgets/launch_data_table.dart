import 'package:flutter/material.dart';

class LaunchDataTable extends StatelessWidget {
  const LaunchDataTable({
    super.key,
    required this.title,
    required this.columns,
    required this.rowCount,
    required this.cellBuilder,
    this.subtitle,
    this.onAdd,
    this.addLabel = 'Add',
    this.importLabel,
    this.onImport,
    this.emptyMessage = 'No entries yet. Add details to get started.',
  });

  final String title;
  final String? subtitle;
  final List<String> columns;
  final int rowCount;
  final Widget Function(BuildContext context, int rowIdx) cellBuilder;
  final VoidCallback? onAdd;
  final String addLabel;
  final String? importLabel;
  final VoidCallback? onImport;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
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
    return Column(
      children: [
        _buildColumnHeaders(),
        ...List.generate(rowCount, (i) => cellBuilder(context, i)),
      ],
    );
  }

  Widget _buildColumnHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          ...columns.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                c,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Column(
        children: [
          Container(
            color: _hovering ? const Color(0xFFF9FAFB) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                ...widget.cells,
                const Spacer(),
                SizedBox(
                  width: 40,
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

class LaunchEditableCell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final child = TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 12,
        color: const Color(0xFF111827),
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
      ),
    );
    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    if (expand) return Expanded(child: child);
    return child;
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
    final effective = items.contains(value) ? value : items.first;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(effective).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: effective,
            isDense: true,
            isExpanded: true,
            iconSize: 14,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _statusColor(effective),
            ),
            items: items
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
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
