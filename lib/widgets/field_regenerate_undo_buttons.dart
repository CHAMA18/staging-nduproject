import 'package:flutter/material.dart';

/// Reusable field-level regenerate and undo buttons
/// Shows on hover over text fields that have AI-generated content
class FieldRegenerateUndoButtons extends StatelessWidget {
  const FieldRegenerateUndoButtons({
    super.key,
    required this.onRegenerate,
    required this.onUndo,
    required this.canUndo,
    this.isLoading = false,
    this.size = 20,
  });

  final VoidCallback onRegenerate;
  final VoidCallback onUndo;
  final bool canUndo;
  final bool isLoading;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: isLoading
              ? SizedBox(
                  width: size,
                  height: size,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2563EB),
                  ),
                )
              : Icon(Icons.refresh, size: size, color: Colors.grey.shade600),
          tooltip: 'Regenerate this field',
          onPressed: isLoading ? null : onRegenerate,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          splashRadius: 20,
          hoverColor: primary.withValues(alpha: 0.08),
        ),
        IconButton(
          icon: Icon(
            Icons.undo,
            size: size,
            color: canUndo ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          tooltip: 'Undo last change',
          onPressed: canUndo ? onUndo : null,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          splashRadius: 20,
          hoverColor: primary.withValues(alpha: 0.08),
        ),
      ],
    );
  }
}

/// Wrapper widget that shows regenerate/undo buttons on hover
class HoverableFieldControls extends StatefulWidget {
  const HoverableFieldControls({
    super.key,
    required this.child,
    required this.onRegenerate,
    required this.onUndo,
    required this.canUndo,
    this.isAiGenerated = false,
    this.isLoading = false,
  });

  final Widget child;
  final VoidCallback onRegenerate;
  final VoidCallback onUndo;
  final bool canUndo;
  final bool isAiGenerated;
  final bool isLoading;

  @override
  State<HoverableFieldControls> createState() => _HoverableFieldControlsState();
}

class _HoverableFieldControlsState extends State<HoverableFieldControls> {
  bool _isHovering = false;

  void _setHovering(bool value) {
    if (mounted && _isHovering != value) {
      setState(() => _isHovering = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAiGenerated) {
      return widget.child;
    }

    final isMobile = MediaQuery.of(context).size.width < 600;
    final showControls = isMobile || _isHovering;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating action row above the field
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: showControls ? 1.0 : 0.0,
          child: MouseRegion(
            onEnter: (_) => _setHovering(true),
            onExit: (_) => _setHovering(false),
            child: IgnorePointer(
              ignoring: !showControls,
              child: Container(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: Colors.transparent,
                  child: FieldRegenerateUndoButtons(
                    onRegenerate: widget.onRegenerate,
                    onUndo: widget.onUndo,
                    canUndo: widget.canUndo,
                    isLoading: widget.isLoading,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Text field without padding reservation
        MouseRegion(
          onEnter: (_) => _setHovering(true),
          onExit: (_) => _setHovering(false),
          child: widget.child,
        ),
      ],
    );
  }
}
