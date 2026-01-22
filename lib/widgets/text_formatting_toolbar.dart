import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A toolbar for basic text formatting (bold, underline, text size, undo)
/// Works with standard TextField controllers by inserting markdown-like syntax
class TextFormattingToolbar extends StatefulWidget {
  const TextFormattingToolbar({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onBeforeUndo,
  });

  final TextEditingController controller;
  final bool enabled;
  /// Called immediately before undo. Use to save current state to avoid data loss.
  final VoidCallback? onBeforeUndo;

  @override
  State<TextFormattingToolbar> createState() => _TextFormattingToolbarState();
}

class _TextFormattingToolbarState extends State<TextFormattingToolbar> {
  final List<String> _undoHistory = [];
  static const int _maxUndoHistory = 50;
  bool _isUndoAvailable = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _saveToHistory();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Save to history on significant changes (debounced)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.controller.text != (_undoHistory.isEmpty ? '' : _undoHistory.last)) {
        _saveToHistory();
      }
    });
  }

  void _saveToHistory() {
    if (_undoHistory.isEmpty || _undoHistory.last != widget.controller.text) {
      _undoHistory.add(widget.controller.text);
      if (_undoHistory.length > _maxUndoHistory) {
        _undoHistory.removeAt(0);
      }
      setState(() {
        _isUndoAvailable = _undoHistory.length > 1;
      });
    }
  }

  void _insertText(String before, String after) {
    final selection = widget.controller.selection;
    final text = widget.controller.text;
    final start = selection.start;
    final end = selection.end;

    if (start == -1 || end == -1) return;

    final selectedText = text.substring(start, end);
    final newText = text.replaceRange(start, end, '$before$selectedText$after');
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + before.length + selectedText.length + after.length),
    );
  }

  void _applyFormat(String markdownFormat) {
    switch (markdownFormat) {
      case 'bold':
        _insertText('**', '**');
        break;
      case 'italic':
        _insertText('*', '*');
        break;
      case 'underline':
        _insertText('__', '__');
        break;
      case 'h1':
        _insertText('# ', '\n');
        break;
      case 'h2':
        _insertText('## ', '\n');
        break;
      case 'h3':
        _insertText('### ', '\n');
        break;
    }
  }

  void _undo() {
    if (_undoHistory.length <= 1) return;
    widget.onBeforeUndo?.call();
    _undoHistory.removeLast(); // Remove current
    final previous = _undoHistory.last;
    widget.controller.value = TextEditingValue(
      text: previous,
      selection: TextSelection.collapsed(offset: previous.length),
    );
    setState(() {
      _isUndoAvailable = _undoHistory.length > 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold',
            onPressed: () => _applyFormat('bold'),
          ),
          _ToolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic',
            onPressed: () => _applyFormat('italic'),
          ),
          _ToolbarButton(
            icon: Icons.format_underlined,
            tooltip: 'Underline',
            onPressed: () => _applyFormat('underline'),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          _ToolbarButton(
            icon: Icons.text_fields,
            tooltip: 'Heading 1',
            onPressed: () => _applyFormat('h1'),
          ),
          _ToolbarButton(
            icon: Icons.title,
            tooltip: 'Heading 2',
            onPressed: () => _applyFormat('h2'),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          _ToolbarButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            onPressed: _isUndoAvailable ? _undo : null,
            isDisabled: !_isUndoAvailable,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isDisabled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: isDisabled || onPressed == null ? Colors.grey[400] : Colors.black87,
        onPressed: onPressed,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}
