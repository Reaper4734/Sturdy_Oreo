import 'dart:ui';
import 'knowledge_graph_model.dart';

/// Represents a validated, auto-fitted container bounding box for a group of nodes.
class ContainerBox {
  final String id;
  final String label;
  final Rect bounds;
  final NodeType groupType;
  final List<String> childNodeIds;

  const ContainerBox({
    required this.id,
    required this.label,
    required this.bounds,
    required this.groupType,
    this.childNodeIds = const [],
  });
}

/// Immutable result output of the 10-stage layout pipeline, consumed by the pure renderer.
class LayoutResult {
  final Map<String, NodeGeometry> nodeGeometries;
  final List<GraphNode> visibleNodes;
  final List<GraphEdge> routedEdges;
  final List<ContainerBox> containerBoxes;
  final Rect totalBounds;
  final bool isValidated;

  const LayoutResult({
    required this.nodeGeometries,
    required this.visibleNodes,
    required this.routedEdges,
    required this.containerBoxes,
    required this.totalBounds,
    this.isValidated = true,
  });
}
