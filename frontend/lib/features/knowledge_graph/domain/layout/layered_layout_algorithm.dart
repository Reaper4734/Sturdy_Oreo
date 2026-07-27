import 'dart:math' as math;
import '../models/knowledge_graph_model.dart';
import '../models/graph_theme.dart';

/// Single-responsibility layered layout algorithm (ELK Layering / Sugiyama style).
/// Its only responsibility is assigning vertical layered ranks and horizontal coordinates to visible nodes.
/// It must NOT resize containers, validate layouts, calculate edge paths, or manage visibility.
class LayeredLayoutAlgorithm {
  /// Assigns layered positions to visible nodes in the graph using GraphTheme rules.
  static Map<String, NodeGeometry> assignLayers(List<GraphNode> visibleNodes, GraphTheme theme) {
    final Map<String, GraphNode> nodeMap = {for (final n in visibleNodes) n.id: n};

    // Separate into trunk milestones (sections, topics, projects, assessments) and branch items
    final List<GraphNode> trunkNodes = [];
    final Map<String, List<GraphNode>> branchChildren = {};

    for (final node in visibleNodes) {
      if (node.type == NodeType.section ||
          node.type == NodeType.topic ||
          node.type == NodeType.assessment ||
          node.type == NodeType.project) {
        trunkNodes.add(node);
      } else {
        final parentId = node.parentId;
        if (parentId != null && nodeMap.containsKey(parentId)) {
          branchChildren.putIfAbsent(parentId, () => []).add(node);
        } else {
          trunkNodes.add(node);
        }
      }
    }

    double currentY = 80.0;
    final Map<String, NodeGeometry> geometries = {};

    for (int i = 0; i < trunkNodes.length; i++) {
      final trunkNode = trunkNodes[i];
      final optTrunk = calculateOptimalGeometry(trunkNode);
      final double width = optTrunk.width;
      final double height = optTrunk.height;

      // Add rhythm before section headers
      if (i > 0 && trunkNode.type == NodeType.section) {
        currentY += 28.0;
      }

      final double trunkX = theme.trunkCenterX - (width / 2);
      geometries[trunkNode.id] = NodeGeometry(x: trunkX, y: currentY, width: width, height: height);

      final children = branchChildren[trunkNode.id] ?? [];
      double maxBranchBottom = currentY + height;

      if (children.isNotEmpty) {
        double leftY = currentY - 6.0;
        double rightY = currentY - 6.0;

        final bool isAlternativeGroup = children.first.type == NodeType.alternative;
        final bool isReferenceGroup = children.first.type == NodeType.reference || children.first.type == NodeType.resource;

        double maxColW = 0.0;
        if (isAlternativeGroup || isReferenceGroup) {
          for (final c in children) {
            final w = calculateOptimalGeometry(c).width;
            if (w > maxColW) maxColW = w;
          }
        }

        for (int j = 0; j < children.length; j++) {
          final child = children[j];
          final optChild = calculateOptimalGeometry(child);
          final bool isLeft = (isAlternativeGroup || isReferenceGroup) ? false : (j % 2 == 0);
          final double cWidth = (isAlternativeGroup || isReferenceGroup) ? maxColW : optChild.width;
          final double cHeight = optChild.height;

          final double offsetX = isAlternativeGroup ? (theme.branchOffsetX * 0.85) : theme.branchOffsetX;
          final double childX = isLeft
              ? (theme.trunkCenterX - offsetX - cWidth)
              : (theme.trunkCenterX + offsetX);
          final double childY = isLeft ? leftY : rightY;

          geometries[child.id] = NodeGeometry(x: childX, y: childY, width: cWidth, height: cHeight);

          final double gap = isAlternativeGroup ? 10.0 : theme.branchSpacing;
          if (isLeft) {
            leftY += cHeight + gap;
            if (leftY > maxBranchBottom) maxBranchBottom = leftY;
          } else {
            rightY += cHeight + gap;
            if (rightY > maxBranchBottom) maxBranchBottom = rightY;
          }
        }
      }

      final double nextGap = (trunkNode.type == NodeType.section) ? 24.0 : theme.layerSpacing;
      currentY = math.max(currentY + height + nextGap, maxBranchBottom + theme.groupSpacing);
    }

    return geometries;
  }

  /// Returns fixed, deterministic logical dimensions per node type.
  static NodeGeometry calculateOptimalGeometry(GraphNode node) {
    double w = 240.0;
    double h = 58.0;

    switch (node.type) {
      case NodeType.section:
        w = 320.0;
        h = 72.0;
        break;
      case NodeType.topic:
      case NodeType.project:
      case NodeType.assessment:
        w = 260.0;
        h = 84.0;
        break;
      case NodeType.subtopic:
        w = 220.0;
        h = 64.0;
        break;
      case NodeType.quiz:
      case NodeType.alternative:
      case NodeType.optional:
      case NodeType.reference:
      case NodeType.resource:
        w = 200.0;
        h = 56.0;
        break;
    }

    return NodeGeometry(x: node.geometry.x, y: node.geometry.y, width: w, height: h);
  }
}
