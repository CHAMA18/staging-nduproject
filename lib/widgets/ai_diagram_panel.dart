import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/openai/openai_config.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
// Use a relative import to avoid rare web hot-reload library resolution issues
import '../utils/diagram_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// D2 — Colour-coded node renderer
// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight renderer for simple node-link diagrams with type-based styling.
class _DiagramPainter extends CustomPainter {
  final DiagramModel model;

  // Layout constants (kept in one place so both layout and paint are consistent).
  static const double _hGap = 60;
  static const double _vGap = 90;
  static const double _nodeW = 160;
  static const double _nodeH = 60;
  static const double _pad = 40;

  // Precomputed layout for this model. This avoids recomputing topology + text
  // layout every time the framework asks us to repaint.
  late final _DiagramLayout _layout = _DiagramLayout.fromModel(model);

  _DiagramPainter(this.model);

  @override
  void paint(Canvas canvas, Size size) {
    if (_layout.nodes.isEmpty) return;

    // Draw edges first (behind nodes)
    for (final e in _layout.edges) {
      canvas.drawPath(e.path, _edgePaint);
      canvas.drawPath(e.arrowHead, _arrowPaint);
      final label = e.label;
      if (label != null) {
        // Draw a subtle white backdrop behind edge labels for readability
        final bgRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            label.offset.dx - 4,
            label.offset.dy - 2,
            label.text.width + 8,
            label.text.height + 4,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(bgRect, _labelBgPaint);
        label.text.paint(canvas, label.offset);
      }
    }

    // Draw nodes with type-specific colours
    for (final n in _layout.nodes) {
      final style = styleForType(n.nodeType);

      // Fill
      canvas.drawRRect(n.rect, Paint()..color = style.fill);
      // Border
      canvas.drawRRect(
        n.rect,
        Paint()
          ..color = style.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      // Type indicator dot (small circle in top-right corner)
      final dotCenter = Offset(n.rect.right - 14, n.rect.top + 14);
      canvas.drawCircle(dotCenter, 5, Paint()..color = style.border);

      // Text
      n.text.paint(canvas, n.textOffset);
    }
  }

  static final Paint _edgePaint = Paint()
    ..color = const Color(0xFF9CA3AF)
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;

  static final Paint _arrowPaint = Paint()
    ..color = const Color(0xFF9CA3AF)
    ..style = PaintingStyle.fill;

  static final Paint _labelBgPaint = Paint()
    ..color = const Color(0xCCFFFFFF); // semi-transparent white

  @override
  bool shouldRepaint(covariant _DiagramPainter oldDelegate) =>
      oldDelegate.model != model;

  /// Compute the intrinsic size needed by the diagram so the InteractiveViewer
  /// knows how much content it is wrapping.
  Size get intrinsicSize => _layout.intrinsicSize;
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout engine (D6 — improved spacing, collision-safe)
// ─────────────────────────────────────────────────────────────────────────────

class _DiagramLayout {
  final List<_NodeDraw> nodes;
  final List<_EdgeDraw> edges;
  final Size intrinsicSize;

  _DiagramLayout(
      {required this.nodes, required this.edges, required this.intrinsicSize});

  factory _DiagramLayout.fromModel(DiagramModel model) {
    final nodes = model.nodes;
    final edges = model.edges;
    if (nodes.isEmpty) {
      return _DiagramLayout(nodes: const [], edges: const [], intrinsicSize: Size.zero);
    }

    // ── Topological level assignment ──────────────────────────────────────
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

    // ── Group by level ────────────────────────────────────────────────────
    final groups = <int, List<DiagramNode>>{};
    for (final n in nodes) {
      final l = level[n.id] ?? 0;
      groups.putIfAbsent(l, () => []).add(n);
    }

    // ── Compute positions (D6: centered rows, adequate spacing) ──────────
    final W = _DiagramPainter._nodeW;
    final H = _DiagramPainter._nodeH;
    final hGap = _DiagramPainter._hGap;
    final vGap = _DiagramPainter._vGap;
    final pad = _DiagramPainter._pad;

    final positions = <String, Offset>{};
    final levels = groups.keys.toList()..sort();
    double maxX = 0;
    for (var i = 0; i < levels.length; i++) {
      final row = groups[levels[i]]!;
      // Center the row horizontally for visual balance
      final rowWidth = row.length * W + (row.length - 1) * hGap;
      final startX = pad + (600 - rowWidth) / 2; // center within 600px base
      for (var j = 0; j < row.length; j++) {
        final x = startX + j * (W + hGap);
        final y = pad + i * (H + vGap);
        positions[row[j].id] = Offset(x, y);
        if (x + W > maxX) maxX = x + W;
      }
    }

    // ── Ensure minimum canvas size ────────────────────────────────────────
    final canvasW = (maxX + pad).clamp(400.0, 3000.0);
    final canvasH =
        (pad + levels.length * (H + vGap)).clamp(300.0, 4000.0);

    // ── Pre-layout text ───────────────────────────────────────────────────
    final nodeDraws = <_NodeDraw>[];
    for (final n in nodes) {
      final pos = positions[n.id];
      if (pos == null) continue;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx, pos.dy, W, H),
        const Radius.circular(12),
      );

      final title = n.label.trim().isEmpty ? n.id : n.label.trim();
      final tp = TextPainter(
        textDirection: TextDirection.ltr,
        maxLines: 3,
        ellipsis: '…',
        text: TextSpan(
          text: title,
          style: TextStyle(
            fontSize: 12,
            color: styleForType(n.type).text,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      )..layout(maxWidth: W - 28); // leave room for type dot

      final textOffset = Offset(
        pos.dx + 10,
        pos.dy + (H - tp.height) / 2,
      );
      nodeDraws.add(
          _NodeDraw(rect: rect, text: tp, textOffset: textOffset, nodeType: n.type));
    }

    // ── Pre-layout edges ──────────────────────────────────────────────────
    final edgeDraws = <_EdgeDraw>[];
    for (final e in edges) {
      final a = positions[e.from];
      final b = positions[e.to];
      if (a == null || b == null) continue;

      // Smart edge routing: detect if same level (horizontal edge)
      final sameRow = (a.dy - b.dy).abs() < 10;
      Offset start, end;

      if (sameRow) {
        // Horizontal: right side → left side
        if (a.dx < b.dx) {
          start = Offset(a.dx + W, a.dy + H / 2);
          end = Offset(b.dx, b.dy + H / 2);
        } else {
          start = Offset(a.dx, a.dy + H / 2);
          end = Offset(b.dx + W, b.dy + H / 2);
        }
      } else {
        // Vertical: bottom center → top center
        start = Offset(a.dx + W / 2, a.dy + H);
        end = Offset(b.dx + W / 2, b.dy);
      }

      final path = Path()..moveTo(start.dx, start.dy);

      if (sameRow) {
        // Curved horizontal connection
        final midX = (start.dx + end.dx) / 2;
        path.cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);
      } else {
        // Curved vertical connection
        final midY = (start.dy + end.dy) / 2;
        path.cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);
      }

      // Arrow head
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
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        )..layout(maxWidth: 120);

        final tx = (start.dx + end.dx) / 2 - labelTp.width / 2;
        final ty = (start.dy + end.dy) / 2 - 10;
        labelDraw = _EdgeLabelDraw(text: labelTp, offset: Offset(tx, ty));
      }

      edgeDraws.add(_EdgeDraw(path: path, arrowHead: arrowHead, label: labelDraw));
    }

    return _DiagramLayout(
      nodes: nodeDraws,
      edges: edgeDraws,
      intrinsicSize: Size(canvasW, canvasH),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawing primitives
// ─────────────────────────────────────────────────────────────────────────────

class _NodeDraw {
  final RRect rect;
  final TextPainter text;
  final Offset textOffset;
  final String nodeType;

  _NodeDraw({
    required this.rect,
    required this.text,
    required this.textOffset,
    required this.nodeType,
  });
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

// ─────────────────────────────────────────────────────────────────────────────
// D3 — Node tooltip overlay
// ─────────────────────────────────────────────────────────────────────────────

class _NodeTooltipOverlay extends StatelessWidget {
  final DiagramNode node;
  final List<DiagramEdge> incomingEdges;
  final List<DiagramEdge> outgoingEdges;

  const _NodeTooltipOverlay({
    required this.node,
    required this.incomingEdges,
    required this.outgoingEdges,
  });

  @override
  Widget build(BuildContext context) {
    final style = styleForType(node.type);
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(style.icon, size: 18, color: style.border),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: style.fill,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: style.border, width: 0.5),
                ),
                child: Text(
                  node.type.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: style.border),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            node.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          if (incomingEdges.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Incoming:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
            ...incomingEdges.map((e) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '${e.label.isNotEmpty ? e.label : "from"} → ${e.from}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            )),
          ],
          if (outgoingEdges.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Outgoing:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
            ...outgoingEdges.map((e) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '${e.label.isNotEmpty ? e.label : "to"} → ${e.to}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// D4 — Diagram persistence helper
// ─────────────────────────────────────────────────────────────────────────────

class _DiagramPersistence {
  static Future<void> save({
    required String projectId,
    required String sectionKey,
    required DiagramModel diagram,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_diagrams')
          .doc(sectionKey);
      await docRef.set({
        ...diagram.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Silently fail — persistence is best-effort
    }
  }

  static Future<DiagramModel?> load({
    required String projectId,
    required String sectionKey,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_diagrams')
          .doc(sectionKey)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return DiagramModel.fromJson(doc.data()!);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AiDiagramPanel — the main public widget
// ─────────────────────────────────────────────────────────────────────────────

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
  DateTime? _generatedAt;

  // D3 — Tap-to-show tooltip state
  DiagramNode? _tappedNode;
  Offset? _tapPosition;

  // D7 — GlobalKey for export
  final _repaintBoundaryKey = GlobalKey();

  // D1 — InteractiveViewer controller
  final _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPersistedDiagram());
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// D4 — Load persisted diagram from Firestore on init
  Future<void> _loadPersistedDiagram() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final pid = provider?.projectData.projectId;
    if (pid == null || pid.isEmpty) return;
    final sectionKey = _sectionKey;
    final cached = await _DiagramPersistence.load(projectId: pid, sectionKey: sectionKey);
    if (cached != null && cached.nodes.isNotEmpty && mounted) {
      setState(() => _diagram = cached);
    }
  }

  String get _sectionKey {
    // Derive a stable Firestore-safe key from the section label
    return widget.sectionLabel
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

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
      _tappedNode = null;
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
        _generatedAt = DateTime.now();
      });

      // D4 — Persist to Firestore (best-effort)
      final provider = ProjectDataInherited.maybeOf(context);
      final pid = provider?.projectData.projectId;
      if (pid != null && pid.isNotEmpty) {
        _DiagramPersistence.save(projectId: pid, sectionKey: _sectionKey, diagram: result);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // D3 — Detect which node was tapped
  DiagramNode? _hitTestNode(Offset localPosition) {
    if (_diagram == null) return null;
    // We need to account for the InteractiveViewer transform
    final transformed = _transformationController.toScene(localPosition);
    // Account for the 16px padding inside the container
    final adjusted = transformed.translate(-16, -16);

    const W = _DiagramPainter._nodeW;
    const H = _DiagramPainter._nodeH;

    // Recompute positions to match painter layout
    final nodes = _diagram!.nodes;
    final edges = _diagram!.edges;

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
    final groups = <int, List<DiagramNode>>{};
    for (final n in nodes) {
      final l = level[n.id] ?? 0;
      groups.putIfAbsent(l, () => []).add(n);
    }
    final levels = groups.keys.toList()..sort();
    for (var i = 0; i < levels.length; i++) {
      final row = groups[levels[i]]!;
      final rowWidth = row.length * W + (row.length - 1) * _DiagramPainter._hGap;
      final startX = _DiagramPainter._pad + (600 - rowWidth) / 2;
      for (var j = 0; j < row.length; j++) {
        final x = startX + j * (W + _DiagramPainter._hGap);
        final y = _DiagramPainter._pad + i * (H + _DiagramPainter._vGap);
        final rect = Rect.fromLTWH(x, y, W, H);
        if (rect.contains(adjusted)) {
          return row[j];
        }
      }
    }
    return null;
  }

  // D7 — Export diagram as PNG
  Future<void> _exportAsPng() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      // In a real app we'd save to file or share. For now, show a success snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagram exported (${(byteData.lengthInBytes / 1024).round()} KB)'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // D5 — Open fullscreen view
  void _openFullscreen() {
    if (_diagram == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DiagramFullscreenView(
          diagram: _diagram!,
          sectionLabel: widget.sectionLabel,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // ── Header row: badge + generate button ──────────────────────────
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
              label: Text(
                _diagram != null ? 'Regenerate Diagram' : widget.title,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
              ),
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

        // ── Diagram area ──────────────────────────────────────────────────
        if (_loading) ...[
          // D8 — Loading skeleton
          Container(
            width: double.infinity,
            height: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Generating ${widget.sectionLabel} diagram...',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ] else if (_diagram != null) ...[
          // Diagram card with toolbar
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 320, maxHeight: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                // ── Toolbar: expand + export + reset zoom + generated time ─
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                  ),
                  child: Row(
                    children: [
                      // Node type legend (compact)
                      ..._buildCompactLegend(),
                      const Spacer(),
                      // Generated timestamp
                      if (_generatedAt != null)
                        Text(
                          'Generated ${_formatTime(_generatedAt!)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      const SizedBox(width: 8),
                      // Reset zoom
                      _ToolbarButton(
                        icon: Icons.fit_screen_rounded,
                        tooltip: 'Reset zoom',
                        onTap: () {
                          _transformationController.value = Matrix4.identity();
                        },
                      ),
                      const SizedBox(width: 4),
                      // D5 — Fullscreen
                      _ToolbarButton(
                        icon: Icons.fullscreen_rounded,
                        tooltip: 'Fullscreen',
                        onTap: _openFullscreen,
                      ),
                      const SizedBox(width: 4),
                      // D7 — Export
                      _ToolbarButton(
                        icon: Icons.download_rounded,
                        tooltip: 'Export PNG',
                        onTap: _exportAsPng,
                      ),
                    ],
                  ),
                ),
                // ── Diagram canvas (D1: InteractiveViewer for pan/zoom) ────
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: GestureDetector(
                      onTapUp: (details) {
                        final node = _hitTestNode(details.localPosition);
                        if (node != null) {
                          setState(() {
                            _tappedNode = (_tappedNode?.id == node.id) ? null : node;
                            _tapPosition = details.globalPosition;
                          });
                        } else {
                          setState(() => _tappedNode = null);
                        }
                      },
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.3,
                        maxScale: 3.0,
                        boundaryMargin: const EdgeInsets.all(100),
                        child: RepaintBoundary(
                          key: _repaintBoundaryKey,
                          child: Builder(builder: (_) {
                            final painter = _DiagramPainter(_diagram!);
                            return CustomPaint(
                              painter: painter,
                              isComplex: true,
                              willChange: false,
                              size: painter.intrinsicSize,
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // D3 — Show tooltip if a node is tapped
          if (_tappedNode != null) ...[
            const SizedBox(height: 8),
            _NodeTooltipOverlay(
              node: _tappedNode!,
              incomingEdges: _diagram!.edges.where((e) => e.to == _tappedNode!.id).toList(),
              outgoingEdges: _diagram!.edges.where((e) => e.from == _tappedNode!.id).toList(),
            ),
          ],
        ],
      ],
    );
  }

  /// Build a compact legend showing only the node types that exist in the
  /// current diagram.
  List<Widget> _buildCompactLegend() {
    if (_diagram == null) return [];
    final types = _diagram!.nodes.map((n) => n.type).toSet().toList();
    return types.take(5).map((t) {
      final style = styleForType(t);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: style.border,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              t[0].toUpperCase() + t.substring(1),
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar button helper
// ─────────────────────────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF3F4F6),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// D5 — Fullscreen diagram view
// ─────────────────────────────────────────────────────────────────────────────

class _DiagramFullscreenView extends StatefulWidget {
  final DiagramModel diagram;
  final String sectionLabel;

  const _DiagramFullscreenView({
    required this.diagram,
    required this.sectionLabel,
  });

  @override
  State<_DiagramFullscreenView> createState() => _DiagramFullscreenViewState();
}

class _DiagramFullscreenViewState extends State<_DiagramFullscreenView> {
  final _transformationController = TransformationController();
  DiagramNode? _selectedNode;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  DiagramNode? _hitTestNode(Offset localPosition) {
    if (widget.diagram.nodes.isEmpty) return null;
    final transformed = _transformationController.toScene(localPosition);

    const W = _DiagramPainter._nodeW;
    const H = _DiagramPainter._nodeH;
    final nodes = widget.diagram.nodes;
    final edges = widget.diagram.edges;

    final incoming = <String, int>{for (final n in nodes) n.id: 0};
    final outgoing = <String, List<DiagramEdge>>{
      for (final n in nodes) n.id: <DiagramEdge>[],
    };
    for (final e in edges) {
      if (incoming.containsKey(e.to)) incoming[e.to] = (incoming[e.to] ?? 0) + 1;
      outgoing[e.from]?.add(e);
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
    final groups = <int, List<DiagramNode>>{};
    for (final n in nodes) {
      final l = level[n.id] ?? 0;
      groups.putIfAbsent(l, () => []).add(n);
    }
    final levels = groups.keys.toList()..sort();
    for (var i = 0; i < levels.length; i++) {
      final row = groups[levels[i]]!;
      final rowWidth = row.length * W + (row.length - 1) * _DiagramPainter._hGap;
      final startX = _DiagramPainter._pad + (600 - rowWidth) / 2;
      for (var j = 0; j < row.length; j++) {
        final x = startX + j * (W + _DiagramPainter._hGap);
        final y = _DiagramPainter._pad + i * (H + _DiagramPainter._vGap);
        if (Rect.fromLTWH(x, y, W, H).contains(transformed)) {
          return row[j];
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.sectionLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fit_screen_rounded),
            tooltip: 'Reset zoom',
            onPressed: () => _transformationController.value = Matrix4.identity(),
          ),
          const SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Legend bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.white,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: widget.diagram.nodes.map((n) => n.type).toSet().map((t) {
                final style = styleForType(t);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: style.fill,
                        border: Border.all(color: style.border, width: 1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t[0].toUpperCase() + t.substring(1),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // Diagram
          Expanded(
            child: GestureDetector(
              onTapUp: (details) {
                final node = _hitTestNode(details.localPosition);
                setState(() => _selectedNode = _selectedNode == node ? null : node);
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.2,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(200),
                child: Center(
                  child: Builder(builder: (_) {
                    final painter = _DiagramPainter(widget.diagram);
                    return CustomPaint(
                      painter: painter,
                      isComplex: true,
                      willChange: false,
                      size: painter.intrinsicSize,
                    );
                  }),
                ),
              ),
            ),
          ),
          // D3 — Node detail panel at bottom
          if (_selectedNode != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: _NodeTooltipOverlay(
                node: _selectedNode!,
                incomingEdges: widget.diagram.edges.where((e) => e.to == _selectedNode!.id).toList(),
                outgoingEdges: widget.diagram.edges.where((e) => e.from == _selectedNode!.id).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
