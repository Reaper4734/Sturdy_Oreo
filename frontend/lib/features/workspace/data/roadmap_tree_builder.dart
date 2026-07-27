import 'package:frontend/shared/models/roadmap_model.dart';

/// Reconstructs a hierarchical tree of [RoadmapNode] from a flat list of
/// JSON-decoded nodes and edges returned by the backend Knowledge Graph API.
///
/// SECTION nodes become top-level expandable parents.
/// Edges from a SECTION to a non-SECTION node create parent→child relationships.
/// Orphan nodes (not claimed by any section) remain top-level.
/// SECTION→SECTION edges are treated as ordering, not containment.
class RoadmapTreeBuilder {
  /// Builds a hierarchical tree + parsed edges from raw JSON maps.
  static ({List<RoadmapNode> tree, List<RoadmapEdge> edges}) build(
    List<dynamic> rawNodes,
    List<dynamic> rawEdges,
  ) {
    final allNodes = <String, RoadmapNode>{};

    // Step 1: Parse all nodes into a lookup map
    for (final n in rawNodes) {
      NodeType parsedType = NodeType.topic;
      if (n['type'] != null) {
        switch (n['type'].toString().toLowerCase()) {
          case 'section':
            parsedType = NodeType.section;
            break;
          case 'topic':
            parsedType = NodeType.topic;
            break;
          case 'project':
            parsedType = NodeType.project;
            break;
          case 'assessment':
            parsedType = NodeType.assessment;
            break;
          case 'capstone':
            parsedType = NodeType.capstone;
            break;
        }
      }

      allNodes[n['id'] ?? 'unknown'] = RoadmapNode(
        id: n['id'] ?? 'unknown',
        title: n['title'] ?? n['label'] ?? 'Module',
        subtitle: n['rationale'] ?? 'AI Generated',
        type: parsedType,
        estimatedHours: n['estimatedHours'],
        difficulty: n['difficulty'],
        status: 'Not Started',
      );
    }

    // Step 2: Parse edges
    final edges = (rawEdges)
        .map((e) => RoadmapEdge(from: e['from'] ?? '', to: e['to'] ?? ''))
        .toList();

    // Step 3: Build tree — assign children to parent SECTION nodes
    // Only nest non-SECTION nodes; SECTION→SECTION edges are ordering, not containment.
    final childIds = <String>{};
    for (final edge in edges) {
      final parent = allNodes[edge.from];
      final child = allNodes[edge.to];
      if (parent != null &&
          child != null &&
          parent.type == NodeType.section &&
          child.type != NodeType.section) {
        parent.children.add(child);
        childIds.add(edge.to);
      }
    }

    // Step 4: Top-level = anything not claimed as a child
    final tree = <RoadmapNode>[];
    for (final node in allNodes.values) {
      if (!childIds.contains(node.id)) {
        tree.add(node);
      }
    }

    return (tree: tree, edges: edges);
  }
}
