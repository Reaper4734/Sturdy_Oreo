import 'dart:ui';
import '../models/knowledge_graph_model.dart';
import '../models/graph_theme.dart';
import '../models/layout_result.dart';

/// Container Layout Engine (auto-sizing and fit-content behavior).
/// Responsibilities: auto-size section containers, calculate bounding boxes, apply consistent padding,
/// center children/parents, support fit-content behavior derived strictly from visible child geometries.
class ContainerLayoutEngine {
  /// Computes container boxes for groups and centers parent nodes over their visible subtrees.
  static ContainerLayoutOutput computeContainers(
    List<GraphNode> visibleNodes,
    Map<String, NodeGeometry> geometries,
    GraphTheme theme,
  ) {
    final Map<String, NodeGeometry> updatedGeometries = Map.from(geometries);
    final List<ContainerBox> containerBoxes = [];

    // Group child nodes by parentId
    final Map<String, List<GraphNode>> childrenByParent = {};
    final Map<String, GraphNode> nodeMap = {for (final n in visibleNodes) n.id: n};

    for (final node in visibleNodes) {
      if (node.parentId != null && nodeMap.containsKey(node.parentId)) {
        childrenByParent.putIfAbsent(node.parentId!, () => []).add(node);
      }
    }

    for (final entry in childrenByParent.entries) {
      final parentId = entry.key;
      final children = entry.value;
      if (children.isEmpty) continue;

      final parentNode = nodeMap[parentId];
      if (parentNode == null) continue;

      // Calculate fit-content union bounding rect of all visible children in this group
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (final child in children) {
        final geom = updatedGeometries[child.id] ?? child.geometry;
        if (geom.x < minX) minX = geom.x;
        if (geom.y < minY) minY = geom.y;
        if (geom.x + geom.width > maxX) maxX = geom.x + geom.width;
        if (geom.y + geom.height > maxY) maxY = geom.y + geom.height;
      }

      if (minX == double.infinity) continue;

      // Check if this group needs an explicit ContainerBox (e.g., alternative or reference groups)
      final bool isAlternativeGroup = children.every((c) => c.type == NodeType.alternative);
      final bool isReferenceGroup = children.every((c) => c.type == NodeType.reference || c.type == NodeType.resource);

      if (isAlternativeGroup || isReferenceGroup || parentNode.type == NodeType.section) {
        final Rect contentRect = Rect.fromLTRB(minX, minY, maxX, maxY);
        final Rect paddedRect = Rect.fromLTRB(
          contentRect.left - theme.containerHorizontalPadding,
          contentRect.top - theme.containerVerticalPadding,
          contentRect.right + theme.containerHorizontalPadding,
          contentRect.bottom + theme.containerVerticalPadding,
        );

        if (isAlternativeGroup || isReferenceGroup) {
          containerBoxes.add(ContainerBox(
            id: '${parentId}_container',
            label: isAlternativeGroup ? 'Alternatives' : 'Resources',
            bounds: paddedRect,
            groupType: isAlternativeGroup ? NodeType.alternative : NodeType.resource,
            childNodeIds: children.map((c) => c.id).toList(),
          ));
        }

        // Center parent node above the subtree column if it's a section or topic parent
        if (parentNode.type == NodeType.section || parentNode.type == NodeType.topic) {
          final parentGeom = updatedGeometries[parentId] ?? parentNode.geometry;
          // Only adjust x if it's not the main spine, or if we want exact subtree centering
          final subtreeCenterX = contentRect.left + contentRect.width / 2;
          if ((subtreeCenterX - theme.trunkCenterX).abs() < 50.0) {
            updatedGeometries[parentId] = parentGeom.copyWith(
              x: subtreeCenterX - parentGeom.width / 2,
            );
          }
        }
      }
    }

    return ContainerLayoutOutput(
      geometries: updatedGeometries,
      containerBoxes: containerBoxes,
    );
  }
}

class ContainerLayoutOutput {
  final Map<String, NodeGeometry> geometries;
  final List<ContainerBox> containerBoxes;

  const ContainerLayoutOutput({
    required this.geometries,
    required this.containerBoxes,
  });
}
