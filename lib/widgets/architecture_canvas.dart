import 'package:flutter/material.dart';
import 'package:ndu_project/theme.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class ArchitectureNode {
  ArchitectureNode({
    required this.id,
    required this.label,
    required this.position,
    this.color,
    this.icon,
  });

  final String id;
  String label;
  Offset position;
  Color? color;
  IconData? icon;
}

class ArchitectureEdge {
  ArchitectureEdge({required this.fromId, required this.toId, this.label = ''});
  final String fromId;
  final String toId;
  String label;
}

class ArchitectureCanvas extends StatefulWidget {
  const ArchitectureCanvas({
    super.key,
    required this.onRequestAddNodeFromDrop,
    required this.nodes,
    required this.edges,
    required this.onNodesChanged,
    required this.onEdgesChanged,
  });

  // Called when an external draggable is dropped onto the canvas; returns a new node
  final ArchitectureNode Function(Offset canvasPosition, dynamic payload) onRequestAddNodeFromDrop;

  final List<ArchitectureNode> nodes;
  final List<ArchitectureEdge> edges;

  final ValueChanged<List<ArchitectureNode>> onNodesChanged;
  final ValueChanged<List<ArchitectureEdge>> onEdgesChanged;

  @override
  State<ArchitectureCanvas> createState() => _ArchitectureCanvasState();
}

const List<Color> _nodeColors = [
  Color(0xFFFFFFFF),
  Color(0xFFEFF6FF),
  Color(0xFFF5F3FF),
  Color(0xFFF0FDFA),
  Color(0xFFFFF7ED),
  Color(0xFFFFF1F2),
];

class _ArchitectureCanvasState extends State<ArchitectureCanvas> {
  late TransformationController _transform;
  bool _connectMode = false;
  String? _selectedForConnection; // node id
  String? _selectedNodeId;
  bool _showGrid = true;

  @override
  void initState() {
    super.initState();
    _transform = TransformationController();
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleConnectMode() {
    setState(() {
      _connectMode = !_connectMode;
      _selectedForConnection = null;
    });
  }

  void _resetView() {
    setState(() {
      _transform.value = Matrix4.identity();
    });
  }

  void _zoom(double factor) {
    // scaleByDouble takes x/y/z/w components.
    final next = Matrix4.copy(_transform.value)..scaleByDouble(factor, factor, 1.0, 1.0);
    setState(() => _transform.value = next);
  }

  void _toggleGrid() {
    setState(() => _showGrid = !_showGrid);
  }

  void _selectNode(String id) {
    setState(() => _selectedNodeId = id);
  }

  void _editSelectedNode() {
    final id = _selectedNodeId;
    if (id == null) return;
    final node = widget.nodes.firstWhere((n) => n.id == id, orElse: () => widget.nodes.first);
    _openNodeEditor(node);
  }

  void _deleteSelectedNode() {
    final id = _selectedNodeId;
    if (id == null) return;
    final newNodes = widget.nodes.where((e) => e.id != id).toList();
    final newEdges = widget.edges.where((e) => e.fromId != id && e.toId != id).toList();
    widget.onNodesChanged(newNodes);
    widget.onEdgesChanged(newEdges);
    setState(() => _selectedNodeId = null);
  }

  Future<void> _openNodeEditor(ArchitectureNode node) async {
    final controller = TextEditingController(text: node.label);
    Color selectedColor = node.color ?? Theme.of(context).colorScheme.surface;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit node'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _nodeColors.map((color) {
                  final isSelected = color.toARGB32() == selectedColor.toARGB32();
                  return InkWell(
                    onTap: () => setState(() => selectedColor = color),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != true) return;
    node.label = controller.text.trim().isEmpty ? node.label : controller.text.trim();
    node.color = selectedColor;
    widget.onNodesChanged(List.of(widget.nodes));
  }

  // Convert global drop position to canvas logical coordinates
  Offset _toCanvasSpace(Offset globalPosition, RenderBox box) {
    final local = box.globalToLocal(globalPosition);
    // Apply inverse of current transform to get into child space
    final Matrix4 m = _transform.value;
    final Matrix4 inv = Matrix4.inverted(m);
    final vm.Vector3 v = vm.Vector3(local.dx, local.dy, 0);
    final vm.Vector3 t = inv.transform3(v);
    return Offset(t.x, t.y);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Drop layer
          LayoutBuilder(
            builder: (context, constraints) {
              return DragTarget<Object>(
                onWillAcceptWithDetails: (data) => true,
                onAcceptWithDetails: (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final canvasPos = _toCanvasSpace(details.offset, box);
                  final newNode = widget.onRequestAddNodeFromDrop(canvasPos, details.data);
                  final nodes = [...widget.nodes, newNode];
                  widget.onNodesChanged(nodes);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    color: AppSemanticColors.subtle,
                    child: InteractiveViewer(
                      transformationController: _transform,
                      boundaryMargin: const EdgeInsets.all(2000),
                      minScale: 0.3,
                      maxScale: 2.5,
                      child: CustomPaint(
                        painter: _showGrid ? _GridPainter() : null,
                        child: Stack(children: [
                          // Edges under nodes
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _EdgePainter(widget.nodes, widget.edges),
                              ),
                            ),
                          ),
                          ...widget.nodes.map((n) => _NodeWidget(
                                key: ValueKey(n.id),
                                node: n,
                                connectMode: _connectMode,
                                selectedForConnection: _selectedForConnection == n.id,
                                isSelected: _selectedNodeId == n.id,
                                onDrag: (delta) {
                                  n.position += delta;
                                  widget.onNodesChanged(List.of(widget.nodes));
                                },
                                onTap: () {
                                  if (_connectMode) {
                                    setState(() {
                                      if (_selectedForConnection == null) {
                                        _selectedForConnection = n.id;
                                      } else if (_selectedForConnection != n.id) {
                                        final newEdges = [...widget.edges, ArchitectureEdge(fromId: _selectedForConnection!, toId: n.id)];
                                        widget.onEdgesChanged(newEdges);
                                        _selectedForConnection = null;
                                        _connectMode = false;
                                      }
                                    });
                                    return;
                                  }
                                  _selectNode(n.id);
                                },
                                onDoubleTap: () => _openNodeEditor(n),
                                onDelete: () {
                                  final newNodes = widget.nodes.where((e) => e.id != n.id).toList();
                                  final newEdges = widget.edges.where((e) => e.fromId != n.id && e.toId != n.id).toList();
                                  widget.onNodesChanged(newNodes);
                                  widget.onEdgesChanged(newEdges);
                                },
                              )),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Toolbar
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppSemanticColors.border),
              ),
              child: Row(children: [
                IconButton(
                  tooltip: 'Reset view',
                  onPressed: _resetView,
                  icon: const Icon(Icons.center_focus_weak, color: Colors.black),
                ),
                IconButton(
                  tooltip: 'Zoom in',
                  onPressed: () => _zoom(1.1),
                  icon: const Icon(Icons.zoom_in, color: Colors.black),
                ),
                IconButton(
                  tooltip: 'Zoom out',
                  onPressed: () => _zoom(0.9),
                  icon: const Icon(Icons.zoom_out, color: Colors.black),
                ),
                const SizedBox(width: 4),
                FilterChip(
                  selected: _connectMode,
                  onSelected: (_) => _toggleConnectMode(),
                  label: const Text('Connect'),
                  avatar: Icon(Icons.trending_flat, color: _connectMode ? Colors.white : Colors.grey[700]),
                  selectedColor: LightModeColors.accent,
                  checkmarkColor: Colors.black,
                  labelStyle: TextStyle(color: _connectMode ? Colors.black : Colors.grey[800], fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  selected: _showGrid,
                  onSelected: (_) => _toggleGrid(),
                  label: const Text('Grid'),
                  selectedColor: const Color(0xFFE2E8F0),
                ),
                const SizedBox(width: 6),
                if (_selectedNodeId != null) ...[
                  IconButton(
                    tooltip: 'Edit node',
                    onPressed: _editSelectedNode,
                    icon: const Icon(Icons.edit, color: Colors.black),
                  ),
                  IconButton(
                    tooltip: 'Delete node',
                    onPressed: _deleteSelectedNode,
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  ),
                ],
                const SizedBox(width: 6),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint pSmall = Paint()
      ..color = const Color(0xFFEFF2F6)
      ..strokeWidth = 1;
    const double step = 24;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), pSmall);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pSmall);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EdgePainter extends CustomPainter {
  _EdgePainter(this.nodes, this.edges);
  final List<ArchitectureNode> nodes;
  final List<ArchitectureEdge> edges;

  @override
  void paint(Canvas canvas, Size size) {
    final nodeById = {for (final n in nodes) n.id: n};
    final paint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final e in edges) {
      final a = nodeById[e.fromId];
      final b = nodeById[e.toId];
      if (a == null || b == null) continue;
      final start = a.position + const Offset(120, 28);
      final end = b.position + const Offset(0, 28);
      final midX = (start.dx + end.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);

      // Arrow head
      const double arrow = 6;
      final p1 = end.translate(-arrow * 1.4, -arrow / 1.4);
      final p2 = end.translate(-arrow * 1.4, arrow / 1.4);
      final tri = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      canvas.drawPath(tri, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) =>
      oldDelegate.nodes != nodes || oldDelegate.edges != edges;
}

class _NodeWidget extends StatelessWidget {
  const _NodeWidget({
    super.key,
    required this.node,
    required this.onDrag,
    required this.onDelete,
    required this.onTap,
    required this.onDoubleTap,
    required this.connectMode,
    required this.selectedForConnection,
    required this.isSelected,
  });

  final ArchitectureNode node;
  final void Function(Offset delta) onDrag;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final bool connectMode;
  final bool selectedForConnection;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = node.color ?? cs.surface;
    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onPanUpdate: (d) => onDrag(d.delta),
        child: Container(
          width: 160,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedForConnection
                  ? LightModeColors.accent
                  : isSelected
                      ? const Color(0xFF2563EB)
                      : AppSemanticColors.border,
              width: selectedForConnection || isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(node.icon ?? Icons.apps, size: 18, color: Colors.blueGrey[800]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.close, size: 16),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Convenience payload class used when dragging from Output Documents or Component Library
class ArchitectureDragPayload {
  ArchitectureDragPayload(this.label, {this.icon, this.color});
  final String label;
  final IconData? icon;
  final Color? color;
}
