import 'package:flutter/material.dart';
import '../../domain/models/layout_result.dart';

/// Renders pre-calculated background container bounding boxes for grouped alternative technologies
/// or clustered resources/subtopics on the canvas stage.
/// Performs zero layout or coordinate calculations (100% dumb renderer).
class GraphGroupPainter extends CustomPainter {
  final List<ContainerBox> containerBoxes;

  const GraphGroupPainter({required this.containerBoxes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final box in containerBoxes) {
      final RRect roundedRect = RRect.fromRectAndRadius(box.bounds, const Radius.circular(12.0));

      // Fill background
      final Paint fillPaint = Paint()
        ..color = const Color(0xFF121212)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(roundedRect, fillPaint);

      // Subtle border
      final Paint borderPaint = Paint()
        ..color = const Color(0xFF262626)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(roundedRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GraphGroupPainter oldDelegate) {
    return oldDelegate.containerBoxes != containerBoxes;
  }
}
