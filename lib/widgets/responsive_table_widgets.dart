import 'package:flutter/material.dart';

/// Responsive wrapper for data tables with horizontal scroll support
class ResponsiveDataTableWrapper extends StatelessWidget {
  final Widget child;
  final double? minWidth;

  const ResponsiveDataTableWrapper({
    super.key,
    required this.child,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minWidth ?? constraints.maxWidth,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Truncated cell for data tables with tooltip
class TruncatedTableCell extends StatelessWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final double? maxWidth;

  const TruncatedTableCell({
    super.key,
    required this.text,
    this.maxLines = 2,
    this.style,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget =Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    if (text.length > 30) {
      return Tooltip(
        message: text,
        child: maxWidth != null
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth!),
                child: textWidget,
              )
            : textWidget,
      );
    }

    return maxWidth != null
        ? ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: textWidget,
          )
        : textWidget;
  }
}
