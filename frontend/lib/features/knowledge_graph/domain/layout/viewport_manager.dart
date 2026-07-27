import 'dart:math' as math;
import 'dart:ui';
import '../models/knowledge_graph_model.dart';

/// Dedicated Viewport Manager handling camera mathematics and culling bounds outside UI widgets.
/// Responsibilities: zoom, pan, focus node, fit graph, center graph, animate camera, virtualization.
class ViewportManager {
  /// Calculates camera translation matrix offset to center on a specific node geometry.
  static Offset calculateFocusOffset(NodeGeometry nodeGeom, Size stageSize, double zoomLevel) {
    final double targetX = (stageSize.width / 2) - (nodeGeom.center.dx * zoomLevel);
    final double targetY = (stageSize.height / 2) - (nodeGeom.center.dy * zoomLevel);
    return Offset(targetX, targetY);
  }

  /// Calculates camera translation and zoom level to fit the entire graph bounds inside stage.
  static ViewportFitResult calculateFitToScreen(Rect totalBounds, Size stageSize, {double padding = 60.0}) {
    if (stageSize.isEmpty || totalBounds.isEmpty) {
      return const ViewportFitResult(zoom: 0.85, offset: Offset.zero);
    }

    final double availableWidth = math.max(stageSize.width - (2 * padding), 100.0);
    final double availableHeight = math.max(stageSize.height - (2 * padding), 100.0);

    final double zoomX = availableWidth / totalBounds.width;
    final double zoomY = availableHeight / totalBounds.height;
    final double zoom = math.min(math.max(math.min(zoomX, zoomY), 0.15), 1.25);

    final double centerX = totalBounds.left + totalBounds.width / 2;
    final double centerY = totalBounds.top + totalBounds.height / 2;

    final double offsetX = (stageSize.width / 2) - (centerX * zoom);
    final double offsetY = (stageSize.height / 2) - (centerY * zoom);

    return ViewportFitResult(zoom: zoom, offset: Offset(offsetX, offsetY));
  }
}

class ViewportFitResult {
  final double zoom;
  final Offset offset;

  const ViewportFitResult({required this.zoom, required this.offset});
}
