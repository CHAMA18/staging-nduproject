import 'package:flutter/material.dart';
import 'package:ndu_project/openai/openai_config.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
// Use a relative import to avoid rare web hot-reload library resolution issues
import '../utils/diagram_model.dart';

// Model classes moved to utils/diagram_model.dart

/// Lightweight renderer for simple node-link diagrams
class _DiagramPainter extends CustomPainter {
  final DiagramModel model;

  // Layout constants (kept in one place so both layout and paint are consistent).
  static const double _hGap = 180;
  static const double _vGap = 110;
  static const double _nodeW = 150;
  static const double _nodeH = 56;
  static const double _pad = 40;

  // Paint objects are relatively expensive to allocate repeatedly during paint.
  // Keep them as fields so a single painter instance can reuse them across paints.
  static final Paint _borderPaint = Paint()
    ..color = const Color(0xFFE5E7EB)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  static final Paint _fillPaint = Paint()..color = Colors.white;
  static final Paint _edgePaint = Paint()
    ..color = const Color(0xFF9CA3AF)
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;
  static final Paint _arrowPaint = Paint()
    ..color = const Color(0xFF9CA3AF)
    ..style = PaintingStyle.fill;

  // Precomputed layout for this model. This avoids recomputing topology + text
  // layout every time the framework asks us to repaint.
  late final _DiagramLayout _layout = _DiagramLayout.fromModel(model);

  _DiagramPainter(this.model);

  @override
  void paint(Canvas canvas, Size size) {
    if (_layout.nodes.isEmpty) return;

    // draw edges
    for (final e in _layout.edges) {
      canvas.drawPath(e.path, _edgePaint);
      canvas.drawPath(e.arrowHead, _arrowPaint);
      final label = e.label;
      if (label != null) {
        label.text.paint(canvas, label.offset);
      }
    }

    // draw nodes
    for (final n in _layout.nodes) {
      canvas.drawRRect(n.rect, _fillPaint);
      canvas.drawRRect(n.rect, _borderPaint);
      n.text.paint(canvas, n.textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagramPainter oldDelegate) => oldDelegate.model != model;
}

class _DiagramLayout {
  final List<_NodeDraw> nodes;
  final List<_EdgeDraw> edges;

  _DiagramLayout({required this.nodes, required this.edges});

  factory _DiagramLayout.fromModel(DiagramModel model) {
    final nodes = model.nodes;
    final edges = model.edges;
    if (nodes.isEmpty) return _DiagramLayout(nodes: const [], edges: const []);

    // Simple layered layout: compute levels using a topological traversal.
    // O(nodes + edges), avoids unbounded loops on cyclic graphs.
    final incoming = <String, int>{for (final n in nodes) n.id: 0};
    final outgoing = <String, List<DiagramEdge>>{
      for (final n in nodes) n.id: <DiagramEdge>[],
    };
    for (final e in edges) {
      if (incoming.containsKey(e.to)) {
        incoming[e.to] = (incoming[e.to] ?? 0) + 1;
      }
      final bucket = outgoing[e.from];
      if (bucket != null) bucket.add(e);
    }

    final level = <String, int>{};
    final queue = <String>[
      ...incoming.entries.where((e) => e.value == 0).map((e) => e.key),
    ];
    for (int qi = 0; qi < queue.length; qi++) {
      final id = queue[qi];
      final currentLevel = level[id] ?? 0;
      for (final e in outgoing[id] ?? const <DiagramEdge>[]) {
        final next = e.to;
        if (!incoming.containsKey(next)) continue;
        final nextLevel = level[next] ?? 0;
        if (currentLevel + 1 > nextLevel) level[next] = currentLevel + 1;
        incoming[next] = (incoming[next] ?? 0) - 1;
        if (incoming[next] == 0) queue.add(next);
      }
    }

    // group by level
    final groups = <int, List<DiagramNode>>{};
    for (final n in nodes) {
      final l = level[n.id] ?? 0;
      groups.putIfAbsent(l, () => []).add(n);
    }

    // compute positions (stable for a given model)
    final positions = <String, Offset>{};
    final levels = groups.keys.toList()..sort();
    for (var i = 0; i < levels.length; i++) {
      final l = levels[i];
      final row = groups[l]!;
      for (var j = 0; j < row.length; j++) {
        final x = _DiagramPainter._pad + j * (_DiagramPainter._nodeW + _DiagramPainter._hGap);
        final y = _DiagramPainter._pad + i * (_DiagramPainter._nodeH + _DiagramPainter._vGap);
        positions[row[j].id] = Offset(x, y);
      }
    }

    // Pre-layout text so paint avoids repeated paragraph work.
    final nodeDraws = <_NodeDraw>[];
    for (final n in nodes) {
      final pos = positions[n.id];
      if (pos == null) continue;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx, pos.dy, _DiagramPainter._nodeW, _DiagramPainter._nodeH),
        const Radius.circular(12),
      );

      final title = n.label.trim().isEmpty ? n.id : n.label.trim();
      final tp = TextPainter(
        textDirection: TextDirection.ltr,
        maxLines: 3,
        ellipsis: '…',
        text: TextSpan(
          text: title,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      )..layout(maxWidth: _DiagramPainter._nodeW - 20);

      final textOffset = Offset(
        pos.dx + 10,
        pos.dy + (_DiagramPainter._nodeH - tp.height) / 2,
      );
      nodeDraws.add(_NodeDraw(rect: rect, text: tp, textOffset: textOffset));
    }

    final edgeDraws = <_EdgeDraw>[];
    for (final e in edges) {
      final a = positions[e.from];
      final b = positions[e.to];
      if (a == null || b == null) continue;
      final start = Offset(a.dx + _DiagramPainter._nodeW, a.dy + _DiagramPainter._nodeH / 2);
      final end = Offset(b.dx, b.dy + _DiagramPainter._nodeH / 2);
      final midX = (start.dx + end.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);

      // arrow head
      const double arrow = 6;
      final p1 = end.translate(-arrow * 1.4, -arrow / 1.4);
      final p2 = end.translate(-arrow * 1.4, arrow / 1.4);
      final arrowHead = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      _EdgeLabelDraw? labelDraw;
      final trimmed = e.label.trim();
      if (trimmed.isNotEmpty) {
        final labelTp = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
          text: TextSpan(
            text: trimmed,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        )..layout(maxWidth: 140);

        final tx = (start.dx + end.dx) / 2 - labelTp.width / 2;
        final ty = (start.dy + end.dy) / 2 - 10;
        labelDraw = _EdgeLabelDraw(text: labelTp, offset: Offset(tx, ty));
      }

      edgeDraws.add(_EdgeDraw(path: path, arrowHead: arrowHead, label: labelDraw));
    }

    return _DiagramLayout(nodes: nodeDraws, edges: edgeDraws);
  }
}

class _NodeDraw {
  final RRect rect;
  final TextPainter text;
  final Offset textOffset;

  _NodeDraw({required this.rect, required this.text, required this.textOffset});
}

class _EdgeDraw {
  final Path path;
  final Path arrowHead;
  final _EdgeLabelDraw? label;

  _EdgeDraw({required this.path, required this.arrowHead, required this.label});
}

class _EdgeLabelDraw {
  final TextPainter text;
  final Offset offset;

  _EdgeLabelDraw({required this.text, required this.offset});
}

class AiDiagramPanel extends StatefulWidget {
  const AiDiagramPanel({
    super.key,
    required this.sectionLabel,
    required this.currentTextProvider,
    this.title = 'Generate Diagram',
  });

  final String sectionLabel;
  final String Function() currentTextProvider;
  final String title;

  @override
  State<AiDiagramPanel> createState() => _AiDiagramPanelState();
}

class _AiDiagramPanelState extends State<AiDiagramPanel> {
  DiagramModel? _diagram;
  bool _loading = false;
  String? _error;

  Future<void> _generate() async {
    final text = widget.currentTextProvider().trim();
    final data = ProjectDataHelper.getData(context);
    final sectionLower = widget.sectionLabel.toLowerCase();
    final useExecutiveContext = sectionLower.contains('executive plan') || sectionLower.contains('executive');
    final executiveContext = useExecutiveContext
        ? ProjectDataHelper.buildExecutivePlanContext(data, sectionLabel: widget.sectionLabel)
        : '';
    final projectContext = executiveContext.isNotEmpty
        ? executiveContext
        : ProjectDataHelper.buildFepContext(data, sectionLabel: widget.sectionLabel);
    if (text.isEmpty && projectContext.trim().isEmpty) {
      setState(() => _error = 'Add some notes first to generate a diagram.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await OpenAiDiagramService.instance.generateDiagram(
        section: widget.sectionLabel,
        contextText: text.isNotEmpty ? '$projectContext\n\nUser Notes:\n$text' : projectContext,
      );
      if (!mounted) return;
      setState(() {
        _diagram = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE1EEFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(children: const [
                Icon(Icons.auto_awesome, size: 16, color: Color(0xFFF59E0B)),
                SizedBox(width: 6),
                Text('AI Diagram', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              ]),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.hub_outlined, color: Colors.black),
              label: Text(widget.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        if ((_error ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
        ],
        const SizedBox(height: 12),
        if (_diagram != null)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 240, maxHeight: 520),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _DiagramPainter(_diagram!),
                  isComplex: true,
                  willChange: false,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
