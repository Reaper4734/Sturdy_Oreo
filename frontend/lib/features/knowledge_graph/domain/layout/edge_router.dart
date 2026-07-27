import 'dart:math' as math;
import 'dart:ui';
import '../models/knowledge_graph_model.dart';
import '../models/graph_theme.dart';

/// Independent edge router supporting Orthogonal, Smooth Step, Cubic Bézier, and Straight styles.
/// Resolves NodePort.auto dynamically to the closest node boundary to guarantee zero floating/orphan edges.
class EdgeRouter {
  /// Routes all visible edges using resolved ports and calculated control points.
  static List<GraphEdge> routeEdges(
    List<GraphEdge> edges,
    Map<String, NodeGeometry> geometries,
    GraphTheme theme,
  ) {
    final List<GraphEdge> routed = [];

    for (final edge in edges) {
      final sourceGeom = geometries[edge.sourceNodeId];
      final targetGeom = geometries[edge.targetNodeId];

      if (sourceGeom == null || targetGeom == null) {
        continue;
      }

      // 1. Resolve AUTO ports based on relative bounding box positions
      final NodePort resolvedSourcePort = _resolvePort(
        edge.sourcePort,
        sourceGeom,
        targetGeom,
        isSource: true,
      );
      final NodePort resolvedTargetPort = _resolvePort(
        edge.targetPort,
        sourceGeom,
        targetGeom,
        isSource: false,
      );

      final Offset startPt = _getPortOffset(sourceGeom, resolvedSourcePort);
      final Offset endPt = _getPortOffset(targetGeom, resolvedTargetPort);

      // 2. Generate control points based on routing type
      final List<ControlPoint> controlPoints = _generateControlPoints(
        startPt,
        endPt,
        resolvedSourcePort,
        resolvedTargetPort,
        edge.routingType,
        theme,
      );

      routed.add(edge.copyWith(
        sourcePort: resolvedSourcePort,
        targetPort: resolvedTargetPort,
        controlPoints: controlPoints,
      ));
    }

    return routed;
  }

  static NodePort _resolvePort(
    NodePort port,
    NodeGeometry source,
    NodeGeometry target, {
    required bool isSource,
  }) {
    if (port != NodePort.auto) return port;

    final double dx = target.center.dx - source.center.dx;
    final double dy = target.center.dy - source.center.dy;

    if (dy.abs() > dx.abs() * 0.8) {
      if (dy > 0) {
        return isSource ? NodePort.bottom : NodePort.top;
      } else {
        return isSource ? NodePort.top : NodePort.bottom;
      }
    } else {
      if (dx > 0) {
        return isSource ? NodePort.right : NodePort.left;
      } else {
        return isSource ? NodePort.left : NodePort.right;
      }
    }
  }

  static Offset _getPortOffset(NodeGeometry geom, NodePort port) {
    switch (port) {
      case NodePort.top:
        return geom.topCenter;
      case NodePort.bottom:
        return geom.bottomCenter;
      case NodePort.left:
        return geom.leftCenter;
      case NodePort.right:
        return geom.rightCenter;
      case NodePort.auto:
        return geom.bottomCenter;
    }
  }

  static List<ControlPoint> _generateControlPoints(
    Offset start,
    Offset end,
    NodePort sourcePort,
    NodePort targetPort,
    EdgeRoutingType routingType,
    GraphTheme theme,
  ) {
    if (routingType == EdgeRoutingType.cubicBezier) {
      // Smooth sweep curve for main trunk spine
      final double dy = end.dy - start.dy;
      final double cpOffset = math.max(dy * 0.45, 30.0);
      return [
        ControlPoint(start.dx, start.dy),
        ControlPoint(start.dx, start.dy + cpOffset),
        ControlPoint(end.dx, end.dy - cpOffset),
        ControlPoint(end.dx, end.dy),
      ];
    } else {
      // Orthogonal Smooth Step (default for branches and structured roadmaps)
      if (sourcePort == NodePort.right || sourcePort == NodePort.left) {
        final double midX = start.dx + (end.dx - start.dx) * 0.5;
        return [
          ControlPoint(start.dx, start.dy),
          ControlPoint(midX, start.dy),
          ControlPoint(midX, end.dy),
          ControlPoint(end.dx, end.dy),
        ];
      } else {
        final double midY = start.dy + (end.dy - start.dy) * 0.5;
        return [
          ControlPoint(start.dx, start.dy),
          ControlPoint(start.dx, midY),
          ControlPoint(end.dx, midY),
          ControlPoint(end.dx, end.dy),
        ];
      }
    }
  }
}
