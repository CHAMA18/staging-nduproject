import 'package:flutter/material.dart';
import 'package:ndu_project/openai/openai_config.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
// Use a relative import to avoid rare web hot-reload library resolution issues
import '../utils/diagram_model.dart';

// Model classes moved to utils/diagram_model.dart

/// Lightweight renderer for simple node-link diagrams
class _DiagramPainter extends CustomPainter {
  final DiagramModel model;
  _DiagramPainter(this.model);

  @override
  void paint(Canvas canvas, Size size) {
    // Simple layered layout: compute levels using a topological traversal.
    // This is O(nodes + edges) and avoids unbounded loops on cyclic graphs.
    final nodes = model.nodes;
    final edges = model.edges;
    if (nodes.isEmpty) return;

    final incoming = <String, int>{for (final n in nodes) n.id: 0};
    final outgoing = <String, List<DiagramEdge>>{
      for (final n in nodes) n.id: <DiagramEdge>[],
    };
    for (final e in edges) {
      if (incoming.containsKey(e.to)) incoming[e.to] = (incoming[e.to] ?? 0) + 1;
      final bucket = outgoing[e.from];
      if (bucket != null) bucket.add(e);
    }
    final level = <String, int>{};
    final queue = <String>[...incoming.entries.where((e) => e.value == 0).map((e) => e.key)];
    for (int qi = 0; qi < queue.length; qi++) {
      final id = queue[qi];
      final currentLevel = level[id] ?? 0;
      for (final e in outgoing[id] ?? const <DiagramEdge>[]) {
        final next = e.to;
        if (!incoming.containsKey(next)) continue;
        final nextLevel = (level[next] ?? 0);
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

    // layout constants
    const double hGap = 180;
    const double vGap = 110;
    const double nodeW = 150;
    const double nodeH = 56;

    final positions = <String, Offset>{};
    final levels = groups.keys.toList()..sort();
    for (var i = 0; i < levels.length; i++) {
      final l = levels[i];
      final row = groups[l]!;
      for (var j = 0; j < row.length; j++) {
        final x = 40 + j * (nodeW + hGap);
        final y = 40 + i * (nodeH + vGap);
        positions[row[j].id] = Offset(x, y);
      }
    }

    final border = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()..color = Colors.white;
    final textPainter = TextPainter(textDirection: TextDirection.ltr, maxLines: 3, ellipsis: '…');

    // draw edges
    final edgePaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final arrowPaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..style = PaintingStyle.fill;
    for (final e in edges) {
      final a = positions[e.from];
      final b = positions[e.to];
      if (a == null || b == null) continue;
      final start = Offset(a.dx + nodeW, a.dy + nodeH / 2);
      final end = Offset(b.dx, b.dy + nodeH / 2);
      final midX = (start.dx + end.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);
      canvas.drawPath(path, edgePaint);

      // arrow head
      const double arrow = 6;
      final p1 = end.translate(-arrow * 1.4, -arrow / 1.4);
      final p2 = end.translate(-arrow * 1.4, arrow / 1.4);
      final tri = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      canvas.drawPath(tri, arrowPaint);

      if (e.label.trim().isNotEmpty) {
        textPainter.text = TextSpan(
          text: e.label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
        );
        textPainter.layout(maxWidth: 140);
        final tx = (start.dx + end.dx) / 2 - textPainter.width / 2;
        final ty = (start.dy + end.dy) / 2 - 10;
        textPainter.paint(canvas, Offset(tx, ty));
      }
    }

    // draw nodes
    for (final n in nodes) {
      final pos = positions[n.id];
      if (pos == null) continue;
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx, pos.dy, nodeW, nodeH), const Radius.circular(12));
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, border);

      final title = n.label.trim().isEmpty ? n.id : n.label.trim();
      textPainter.text = TextSpan(
        text: title,
        style: const TextStyle(fontSize: 13, color: Color(0xFF111827), fontWeight: FontWeight.w600, height: 1.2),
      );
      textPainter.layout(maxWidth: nodeW - 20);
      final tp = Offset(pos.dx + 10, pos.dy + (nodeH - textPainter.height) / 2);
      textPainter.paint(canvas, tp);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagramPainter oldDelegate) => oldDelegate.model != model;
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
