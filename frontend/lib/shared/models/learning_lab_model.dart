import 'package:flutter/material.dart';

class TranscriptLine {
  final String id;
  final int timestampSeconds;
  final String formattedTime; // e.g. "05:42" (No square brackets)
  final String text;

  TranscriptLine({
    required this.id,
    required this.timestampSeconds,
    required this.formattedTime,
    required this.text,
  });
}

class CanvasGridCell {
  final String id;
  final int gridX;
  final int gridY;
  final double width;
  final double height;
  final String title;
  final String diagramType;
  final List<String> nodeLabels;
  bool isSelected;

  CanvasGridCell({
    required this.id,
    required this.gridX,
    required this.gridY,
    required this.width,
    required this.height,
    required this.title,
    required this.diagramType,
    required this.nodeLabels,
    this.isSelected = false,
  });

  Rect get rect => Rect.fromLTWH(gridX * 320.0 + 20, gridY * 240.0 + 20, width, height);
}

class CanvasObject {
  final String id;
  final String label;
  Offset position;
  Size size;
  bool isSelected;
  bool isLocked;

  CanvasObject({
    required this.id,
    required this.label,
    required this.position,
    this.size = const Size(140, 80),
    this.isSelected = false,
    this.isLocked = false,
  });

  Rect get rect => Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}

/// Drawing path data for freehand pen strokes
class DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingPath({required this.points, required this.color, required this.strokeWidth});
}

