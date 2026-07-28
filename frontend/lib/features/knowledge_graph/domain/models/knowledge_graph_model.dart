import 'dart:ui';

/// The 10 distinct node types supported by the Oreo Knowledge Graph Engine.
enum NodeType {
  section,     // Collapsible parent section header
  topic,       // Primary trunk learning milestone
  subtopic,    // Orthogonal side branch topic
  quiz,        // Micro quiz activity node
  project,     // Code or architecture project activity node
  assessment,  // Mastery evaluation assessment node
  reference,   // External doc or documentation link node
  optional,    // Optional learning branch node (dashed border)
  alternative, // Nested alternative item inside a group container
  resource,    // Resource library or video link node
}

/// Node attachment port for edge routing.
enum NodePort {
  top,
  bottom,
  left,
  right,
  auto,
}

/// Routing strategy for connecting edges.
enum EdgeRoutingType {
  orthogonalSmoothStep, // 90-degree bends with rounded 8px corners (side branches)
  cubicBezier,          // Smooth sweep curve (main trunk milestones)
}

/// Progress state of a concept node.
enum NodeStatus {
  notStarted,
  inProgress,
  completed,
  skipped,
}

/// 2D geometry bounding box for node placement on the canvas stage.
class NodeGeometry {
  final double x;
  final double y;
  final double width;
  final double height;

  const NodeGeometry({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  NodeGeometry copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return NodeGeometry(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Rect toRect() => Rect.fromLTWH(x, y, width, height);
  Offset get center => Offset(x + width / 2, y + height / 2);
  Offset get topCenter => Offset(x + width / 2, y);
  Offset get bottomCenter => Offset(x + width / 2, y + height);
  Offset get leftCenter => Offset(x, y + height / 2);
  Offset get rightCenter => Offset(x + width, y + height / 2);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}

/// Visual style properties for connecting edges.
class EdgeStyle {
  final String strokeColorHex;
  final double strokeWidth;
  final bool isDashed;
  final bool showArrowhead;

  const EdgeStyle({
    this.strokeColorHex = '#94A3B8',
    this.strokeWidth = 2.0,
    this.isDashed = false,
    this.showArrowhead = true,
  });

  Color get strokeColor {
    try {
      final hex = strokeColorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF94A3B8);
    }
  }

  Map<String, dynamic> toJson() => {
        'strokeColorHex': strokeColorHex,
        'strokeWidth': strokeWidth,
        'isDashed': isDashed,
        'showArrowhead': showArrowhead,
      };
}

/// A 2D control point for Bézier or orthogonal routing.
class ControlPoint {
  final double x;
  final double y;

  const ControlPoint(this.x, this.y);

  Offset toOffset() => Offset(x, y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

/// Metadata attached to a node for UI badges and activity routing.
class NodeMetadata {
  final int estimatedHours;
  final String difficulty; // e.g., 'BEGINNER', 'INTERMEDIATE', 'ADVANCED'
  final String? activityType; // e.g., 'VIDEO_LESSON', 'CODE_CHALLENGE'
  final int resourceCount;

  const NodeMetadata({
    this.estimatedHours = 2,
    this.difficulty = 'INTERMEDIATE',
    this.activityType,
    this.resourceCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'estimatedHours': estimatedHours,
        'difficulty': difficulty,
        if (activityType != null) 'activityType': activityType,
        'resourceCount': resourceCount,
      };
}

/// Represents an individual concept or container on the Knowledge Graph.
class GraphNode {
  final String id;
  final NodeType type;
  final String label;
  final String description;
  final NodeStatus status;
  final bool isOptional;
  final String? parentId; // For DAG hierarchy or grouping
  final List<String> childrenNodeIds; // For GROUP_CONTAINER or SECTION hierarchy
  final NodeGeometry geometry;
  final NodeMetadata metadata;

  const GraphNode({
    required this.id,
    required this.type,
    required this.label,
    required this.description,
    this.status = NodeStatus.notStarted,
    this.isOptional = false,
    this.parentId,
    this.childrenNodeIds = const [],
    required this.geometry,
    this.metadata = const NodeMetadata(),
  });

  GraphNode copyWith({
    String? id,
    NodeType? type,
    String? label,
    String? description,
    NodeStatus? status,
    bool? isOptional,
    String? parentId,
    List<String>? childrenNodeIds,
    NodeGeometry? geometry,
    NodeMetadata? metadata,
  }) {
    return GraphNode(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      description: description ?? this.description,
      status: status ?? this.status,
      isOptional: isOptional ?? this.isOptional,
      parentId: parentId ?? this.parentId,
      childrenNodeIds: childrenNodeIds ?? this.childrenNodeIds,
      geometry: geometry ?? this.geometry,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'description': description,
        'status': status.name,
        'isOptional': isOptional,
        if (parentId != null) 'parentId': parentId,
        if (childrenNodeIds.isNotEmpty) 'childrenNodeIds': childrenNodeIds,
        'geometry': geometry.toJson(),
        'metadata': metadata.toJson(),
      };
}

/// A directed connecting path between two nodes.
class GraphEdge {
  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final NodePort sourcePort;
  final NodePort targetPort;
  final EdgeRoutingType routingType;
  final EdgeStyle style;
  final List<ControlPoint> controlPoints;

  const GraphEdge({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.sourcePort = NodePort.auto,
    this.targetPort = NodePort.auto,
    this.routingType = EdgeRoutingType.orthogonalSmoothStep,
    this.style = const EdgeStyle(),
    this.controlPoints = const [],
  });

  GraphEdge copyWith({
    String? id,
    String? sourceNodeId,
    String? targetNodeId,
    NodePort? sourcePort,
    NodePort? targetPort,
    EdgeRoutingType? routingType,
    EdgeStyle? style,
    List<ControlPoint>? controlPoints,
  }) {
    return GraphEdge(
      id: id ?? this.id,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      sourcePort: sourcePort ?? this.sourcePort,
      targetPort: targetPort ?? this.targetPort,
      routingType: routingType ?? this.routingType,
      style: style ?? this.style,
      controlPoints: controlPoints ?? this.controlPoints,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceNodeId': sourceNodeId,
        'targetNodeId': targetNodeId,
        'sourcePort': sourcePort.name,
        'targetPort': targetPort.name,
        'routingType': routingType.name,
        'style': style.toJson(),
        if (controlPoints.isNotEmpty)
          'controlPoints': controlPoints.map((c) => c.toJson()).toList(),
      };
}

/// Initial camera view settings for the interactive viewport stage.
class ViewportDefaults {
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final double defaultCenterX;
  final double defaultCenterY;

  const ViewportDefaults({
    this.initialZoom = 0.85,
    this.minZoom = 0.15,
    this.maxZoom = 3.0,
    this.defaultCenterX = 600.0,
    this.defaultCenterY = 150.0,
  });

  Map<String, dynamic> toJson() => {
        'initialZoom': initialZoom,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'defaultCenterX': defaultCenterX,
        'defaultCenterY': defaultCenterY,
      };
}

/// The root Knowledge Graph data structure representing a complete roadmap.
class KnowledgeGraph {
  final String graphId;
  final String title;
  final String description;
  final String version;
  final ViewportDefaults viewportDefaults;
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  const KnowledgeGraph({
    required this.graphId,
    required this.title,
    required this.description,
    this.version = '1.0.0',
    this.viewportDefaults = const ViewportDefaults(),
    required this.nodes,
    required this.edges,
  });

  KnowledgeGraph copyWith({
    String? graphId,
    String? title,
    String? description,
    String? version,
    ViewportDefaults? viewportDefaults,
    List<GraphNode>? nodes,
    List<GraphEdge>? edges,
  }) {
    return KnowledgeGraph(
      graphId: graphId ?? this.graphId,
      title: title ?? this.title,
      description: description ?? this.description,
      version: version ?? this.version,
      viewportDefaults: viewportDefaults ?? this.viewportDefaults,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  /// Calculates total canvas width required by all nodes.
  double get totalCanvasWidth {
    if (nodes.isEmpty) return 1200.0;
    double maxRight = 1200.0;
    for (final node in nodes) {
      if (node.geometry.x + node.geometry.width + 200.0 > maxRight) {
        maxRight = node.geometry.x + node.geometry.width + 200.0;
      }
    }
    return maxRight;
  }

  /// Calculates total canvas height required by all nodes.
  double get totalCanvasHeight {
    if (nodes.isEmpty) return 1000.0;
    double maxBottom = 1000.0;
    for (final node in nodes) {
      if (node.geometry.y + node.geometry.height + 200.0 > maxBottom) {
        maxBottom = node.geometry.y + node.geometry.height + 200.0;
      }
    }
    return maxBottom;
  }

  Map<String, dynamic> toJson() => {
        'graphId': graphId,
        'title': title,
        'description': description,
        'version': version,
        'viewportDefaults': viewportDefaults.toJson(),
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };
}
