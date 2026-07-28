import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/knowledge_graph_model.dart';

/// Renders a compact bottom-right radar minimap preview of the entire Knowledge Graph.
/// Clicking or dragging inside the minimap moves the viewport camera stage.
class GraphMinimapWidget extends StatelessWidget {
  final KnowledgeGraph graph;
  final TransformationController transformationController;
  final Size viewportSize;
  final double minimapWidth;
  final double minimapHeight;

  const GraphMinimapWidget({
    super.key,
    required this.graph,
    required this.transformationController,
    required this.viewportSize,
    this.minimapWidth = 180.0,
    this.minimapHeight = 140.0,
  });

  @override
  Widget build(BuildContext context) {
    final double totalW = graph.totalCanvasWidth;
    final double totalH = graph.totalCanvasHeight;
    final double scaleX = minimapWidth / totalW;
    final double scaleY = minimapHeight / totalH;

    return Container(
      width: minimapWidth,
      height: minimapHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF141414).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFF333333), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            // 1. Draw mini node rectangles
            CustomPaint(
              size: Size(minimapWidth, minimapHeight),
              painter: _MinimapNodesPainter(
                nodes: graph.nodes,
                scaleX: scaleX,
                scaleY: scaleY,
              ),
            ),
            // 2. Draw camera viewport rectangle overlay
            AnimatedBuilder(
              animation: transformationController,
              builder: (context, child) {
                final Matrix4 matrix = transformationController.value;
                final double zoom = matrix.getMaxScaleOnAxis();
                final double transX = -matrix.getTranslation().x / zoom;
                final double transY = -matrix.getTranslation().y / zoom;

                final double viewW = viewportSize.width / zoom;
                final double viewH = viewportSize.height / zoom;

                final double boxX = (transX * scaleX).clamp(0.0, minimapWidth - 10.0);
                final double boxY = (transY * scaleY).clamp(0.0, minimapHeight - 10.0);
                final double boxW = (viewW * scaleX).clamp(10.0, minimapWidth);
                final double boxH = (viewH * scaleY).clamp(10.0, minimapHeight);

                return Positioned(
                  left: boxX,
                  top: boxY,
                  width: boxW,
                  height: boxH,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF67E8F9).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFF67E8F9), width: 1.5),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimapNodesPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final double scaleX;
  final double scaleY;

  const _MinimapNodesPainter({
    required this.nodes,
    required this.scaleX,
    required this.scaleY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (final node in nodes) {
      switch (node.status) {
        case NodeStatus.completed:
          paint.color = const Color(0xFF10B981);
        case NodeStatus.inProgress:
          paint.color = const Color(0xFF67E8F9);
        default:
          paint.color = const Color(0xFF444444);
      }

      final Rect rect = Rect.fromLTWH(
        node.geometry.x * scaleX,
        node.geometry.y * scaleY,
        math.max(node.geometry.width * scaleX, 4.0),
        math.max(node.geometry.height * scaleY, 3.0),
      );

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapNodesPainter oldDelegate) {
    return oldDelegate.nodes != nodes;
  }
}
