import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/responsive.dart';

/// Sidebar wrapper with a draggable handle to collapse or expand it.
class DraggableSidebar extends StatefulWidget {
  const DraggableSidebar({
    super.key,
    required this.child,
    required this.openWidth,
    this.collapsedWidth = 0,
    this.animationDuration = const Duration(milliseconds: 220),
  });

  final Widget child;
  final double openWidth;
  final double collapsedWidth;
  final Duration animationDuration;

  @override
  State<DraggableSidebar> createState() => _DraggableSidebarState();
}

class _DraggableSidebarState extends State<DraggableSidebar> {
  // Shared width across all DraggableSidebar instances so the collapsed/expanded
  // state persists when navigating between screens.
  static double? _sharedWidth;

  late double _currentWidth = widget.openWidth;
  bool _dragging = false;

  double get _snapThreshold => (widget.openWidth + widget.collapsedWidth) / 2;
  bool get _isCollapsed => _currentWidth <= widget.collapsedWidth + 1;

  @override
  void didUpdateWidget(covariant DraggableSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openWidth != widget.openWidth ||
        oldWidget.collapsedWidth != widget.collapsedWidth) {
      // Clamp the current/shared width to the new constraints
      final double baseWidth = (_sharedWidth ?? _currentWidth);
      _currentWidth = baseWidth
          .clamp(widget.collapsedWidth, widget.openWidth);
      _sharedWidth = _currentWidth;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize from shared width if available; otherwise start open.
    _currentWidth = (_sharedWidth ?? widget.openWidth)
        .clamp(widget.collapsedWidth, widget.openWidth);
  }

  void _toggleSidebar() {
    setState(() {
      _currentWidth = _isCollapsed ? widget.openWidth : widget.collapsedWidth;
      _dragging = false;
      _sharedWidth = _currentWidth;
    });
  }

  void _handleDragUpdate(double delta) {
    if (delta == 0) return;
    setState(() {
      _dragging = true;
      _currentWidth = (_currentWidth + delta)
          .clamp(widget.collapsedWidth, widget.openWidth);
      _sharedWidth = _currentWidth;
    });
  }

  void _handleDragEnd() {
    setState(() {
      _currentWidth =
          _currentWidth > _snapThreshold ? widget.openWidth : widget.collapsedWidth;
      _dragging = false;
      _sharedWidth = _currentWidth;
    });
  }

  void _openMobileMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.92;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: widget.child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return Container(
        width: 48,
        alignment: Alignment.topCenter,
        child: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF374151)),
          onPressed: _openMobileMenu,
          tooltip: 'Open menu',
        ),
      );
    }

    final bool collapsed = _isCollapsed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: _dragging ? Duration.zero : widget.animationDuration,
          curve: Curves.easeOutCubic,
          width: _currentWidth,
          child: IgnorePointer(
            ignoring: collapsed,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: collapsed ? 0 : 1,
              child: widget.child,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleSidebar,
          onHorizontalDragStart: (_) => setState(() => _dragging = true),
          onHorizontalDragUpdate: (details) =>
              _handleDragUpdate(details.primaryDelta ?? 0),
          onHorizontalDragEnd: (_) => _handleDragEnd(),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: Tooltip(
              message: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
              child: Container(
                width: 32,
                height: double.infinity,
                alignment: Alignment.center,
                child: Container(
                  width: 28,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      collapsed ? Icons.chevron_right : Icons.chevron_left,
                      size: 20,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
