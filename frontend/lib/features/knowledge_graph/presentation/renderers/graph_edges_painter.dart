import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../../domain/models/knowledge_graph_model.dart';

/// Hardware-accelerated CustomPainter rendering all graph edges, Bézier curves,
/// orthogonal rounded connectors, dashed optional lines, and arrowheads.
class GraphEdgesPainter extends CustomPainter {
  final List<GraphEdge> edges;
  final Set<String> activeNodeIds;

  const GraphEdgesPainter({
    required this.edges,
    this.activeNodeIds = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      if (edge.controlPoints.isEmpty) continue;

      final bool isActive = activeNodeIds.contains(edge.sourceNodeId) ||
                            activeNodeIds.contains(edge.targetNodeId);

      final Paint paint = Paint()
        ..color = isActive ? const Color(0xFF67E8F9) : const Color(0xFF383838)
        ..strokeWidth = isActive ? edge.style.strokeWidth + 0.5 : edge.style.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      List<ControlPoint> pointsToDraw = edge.controlPoints;
      if (edge.style.showArrowhead && edge.controlPoints.length >= 2) {
        final Offset endPoint = edge.controlPoints.last.toOffset();
        final Offset prevPoint = edge.controlPoints[edge.controlPoints.length - 2].toOffset();
        final double angle = math.atan2(endPoint.dy - prevPoint.dy, endPoint.dx - prevPoint.dx);
        
        // Stop line stroke slightly before tip so round stroke cap stops inside arrowhead
        final Offset shortenedEnd = Offset(
          endPoint.dx - 3.5 * math.cos(angle),
          endPoint.dy - 3.5 * math.sin(angle),
        );
        pointsToDraw = List.from(edge.controlPoints);
        pointsToDraw[pointsToDraw.length - 1] = ControlPoint(shortenedEnd.dx, shortenedEnd.dy);
      }

      final Path path = _buildPath(pointsToDraw, edge.routingType);

      if (edge.style.isDashed) {
        final dashedPath = dashPath(
          path,
          dashArray: CircularIntervalList<double>([6.0, 4.0]),
        );
        canvas.drawPath(dashedPath, paint);
      } else {
        canvas.drawPath(path, paint);
      }

      if (edge.style.showArrowhead && edge.controlPoints.length >= 2) {
        _drawArrowhead(
          canvas,
          paint..style = PaintingStyle.fill,
          edge.controlPoints[edge.controlPoints.length - 2].toOffset(),
          edge.controlPoints.last.toOffset(),
        );
      }
    }
  }

  Path _buildPath(List<ControlPoint> points, EdgeRoutingType routingType) {
    final Path path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.x, points.first.y);

    if (routingType == EdgeRoutingType.cubicBezier && points.length == 4) {
      path.cubicTo(
        points[1].x, points[1].y,
        points[2].x, points[2].y,
        points[3].x, points[3].y,
      );
    } else if (points.length == 4) {
      // Orthogonal routing with adaptive rounded corners
      final Offset p0 = points[0].toOffset();
      final Offset p1 = points[1].toOffset();
      final Offset p2 = points[2].toOffset();
      final Offset p3 = points[3].toOffset();

      final double radius = math.min(8.0, math.min((p1.dx - p0.dx).abs() * 0.4, (p2.dy - p1.dy).abs() * 0.4));

      // Horizontal out to p1, bend 90 degrees to p2, bend 90 degrees into p3
      if ((p1.dx - p0.dx).abs() > radius * 2 && (p2.dy - p1.dy).abs() > radius * 2) {
        final double signX = (p1.dx - p0.dx).sign;
        final double signY = (p2.dy - p1.dy).sign;
        final double signX2 = (p3.dx - p2.dx).sign;

        path.lineTo(p1.dx - signX * radius, p1.dy);
        path.quadraticBezierTo(p1.dx, p1.dy, p1.dx, p1.dy + signY * radius);
        path.lineTo(p2.dx, p2.dy - signY * radius);
        path.quadraticBezierTo(p2.dx, p2.dy, p2.dx + signX2 * radius, p2.dy);
        path.lineTo(p3.dx, p3.dy);
      } else {
        // Fallback straight segmented path
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].x, points[i].y);
        }
      }
    } else {
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }
    }

    return path;
  }

  void _drawArrowhead(Canvas canvas, Paint paint, Offset from, Offset to) {
    const double arrowSize = 6.0;
    final double angle = math.atan2(to.dy - from.dy, to.dx - from.dx);

    final Path arrowPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowSize * math.cos(angle - math.pi / 6),
        to.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        to.dx - arrowSize * math.cos(angle + math.pi / 6),
        to.dy - arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant GraphEdgesPainter oldDelegate) {
    return oldDelegate.edges != edges || oldDelegate.activeNodeIds != activeNodeIds;
  }
}
