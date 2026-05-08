class DiagramNode {
  final String id;
  final String label;
  final String type; // e.g., start, process, decision, system, output, end
  const DiagramNode({required this.id, required this.label, this.type = 'process'});
}

class DiagramEdge {
  final String from;
  final String to;
  final String label;
  const DiagramEdge({required this.from, required this.to, this.label = ''});
}

class DiagramModel {
  final List<DiagramNode> nodes;
  final List<DiagramEdge> edges;
  const DiagramModel({required this.nodes, required this.edges});
}
