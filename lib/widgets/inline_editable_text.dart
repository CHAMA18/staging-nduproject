import 'package:flutter/material.dart';
import 'package:ndu_project/utils/auto_bullet_text_controller.dart';

/// Inline editable text widget - clicking text turns it into an input field
class InlineEditableText extends StatefulWidget {
  const InlineEditableText({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = '',
    this.style,
    this.textAlign = TextAlign.left,
    this.maxLines = 1,
    this.isListField = false, // If true, uses "." bullet format
    this.isProseField = false, // If true, no bullets, multi-line
    this.showRegenerate = false,
    this.onRegenerate,
    this.isRegenerating = false,
    this.showUndo = false,
    this.onUndo,
    this.canUndo = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;
  final bool isListField;
  final bool isProseField;
  final bool showRegenerate;
  final VoidCallback? onRegenerate;
  final bool isRegenerating;
  final bool showUndo;
  final VoidCallback? onUndo;
  final bool canUndo;

  @override
  State<InlineEditableText> createState() => _InlineEditableTextState();
}

class _InlineEditableTextState extends State<InlineEditableText> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Use AutoBulletTextController for list fields (blockers, nextSteps, etc.)
    // Use regular TextEditingController for prose fields (description, notes)
    if (widget.isListField) {
      _controller = AutoBulletTextController(
          text: widget.value.isEmpty ? '' : widget.value);
    } else {
      _controller = TextEditingController(text: widget.value);
    }
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(InlineEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _controller.text = widget.value;
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      setState(() => _isEditing = false);
      widget.onChanged(_controller.text);
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = widget.value;
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action icons above field
          if (widget.showRegenerate || widget.showUndo)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showRegenerate)
                    IconButton(
                      icon: widget.isRegenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF2563EB)),
                            )
                          : const Icon(Icons.auto_awesome,
                              size: 16, color: Color(0xFF64748B)),
                      onPressed:
                          widget.isRegenerating ? null : widget.onRegenerate,
                      tooltip: 'Regenerate',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  if (widget.showUndo)
                    IconButton(
                      icon: Icon(
                        Icons.undo,
                        size: 16,
                        color: widget.canUndo
                            ? const Color(0xFF64748B)
                            : const Color(0xFFD1D5DB),
                      ),
                      onPressed: widget.canUndo ? widget.onUndo : null,
                      tooltip: 'Undo',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
            ),
          // Text field
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: widget.isProseField ? null : widget.maxLines,
            textAlign: widget.textAlign,
            style: widget.style ??
                const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              isDense: true,
            ),
            onSubmitted: (_) {
              _focusNode.unfocus();
            },
          ),
        ],
      );
    }

    // Display mode - clickable text
    return InkWell(
      onTap: _startEditing,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.value.isEmpty ? widget.hint : widget.value,
                style: widget.value.isEmpty
                    ? (widget.style?.copyWith(color: Colors.grey.shade400) ??
                        TextStyle(fontSize: 13, color: Colors.grey.shade400))
                    : (widget.style ??
                        const TextStyle(
                            fontSize: 13, color: Color(0xFF111827))),
                textAlign: widget.textAlign,
                maxLines: widget.maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
