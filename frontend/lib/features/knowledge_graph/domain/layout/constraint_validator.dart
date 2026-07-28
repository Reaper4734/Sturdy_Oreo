import '../models/knowledge_graph_model.dart';
import '../models/graph_theme.dart';
import '../models/layout_result.dart';
import 'container_layout_engine.dart';
import 'overlap_resolver.dart';

/// Constraint Validator stage in the layout pipeline.
/// Enforces all mandatory layout rules and reruns overlap corrections if validation fails.
class ConstraintValidator {
  /// Validates the layout and applies correction loops if any constraints are violated.
  static ContainerLayoutOutput validateAndCorrect(
    List<GraphNode> visibleNodes,
    List<GraphEdge> visibleEdges,
    Map<String, NodeGeometry> geometries,
    List<ContainerBox> containerBoxes,
    GraphTheme theme,
  ) {
    Map<String, NodeGeometry> validGeom = Map.from(geometries);
    List<ContainerBox> validBoxes = List.from(containerBoxes);

    // Rule 1: No invalid geometry (NaN or infinite coordinates or non-positive dimensions)
    for (final entry in validGeom.entries) {
      final g = entry.value;
      if (g.x.isNaN || g.y.isNaN || g.x.isInfinite || g.y.isInfinite || g.width <= 0 || g.height <= 0) {
        validGeom[entry.key] = NodeGeometry(
          x: g.x.isNaN || g.x.isInfinite ? theme.trunkCenterX : g.x,
          y: g.y.isNaN || g.y.isInfinite ? 100.0 : g.y,
          width: g.width <= 0 ? 200.0 : g.width,
          height: g.height <= 0 ? 50.0 : g.height,
        );
      }
    }

    // Rule 2 & 3: Check for remaining node overlaps or out-of-bounds children
    bool needsRecorrection = false;
    final ids = validGeom.keys.toList();
    for (int i = 0; i < ids.length; i++) {
      for (int j = i + 1; j < ids.length; j++) {
        final rA = validGeom[ids[i]]!.toRect();
        final rB = validGeom[ids[j]]!.toRect();
        if (rA.overlaps(rB)) {
          needsRecorrection = true;
          break;
        }
      }
      if (needsRecorrection) break;
    }

    // Rule 4: Verify all children remain inside their container bounding boxes
    for (final box in validBoxes) {
      for (final childId in box.childNodeIds) {
        final childGeom = validGeom[childId];
        if (childGeom != null) {
          final childRect = childGeom.toRect();
          if (!box.bounds.contains(childRect.topLeft) || !box.bounds.contains(childRect.bottomRight)) {
            needsRecorrection = true;
            break;
          }
        }
      }
      if (needsRecorrection) break;
    }

    // If validation failed, rerun OverlapResolver spacing correction before returning
    if (needsRecorrection) {
      final corrected = OverlapResolver.resolveOverlaps(
        visibleNodes,
        validGeom,
        validBoxes,
        theme,
      );
      validGeom = corrected.geometries;
      validBoxes = corrected.containerBoxes;
    }

    return ContainerLayoutOutput(
      geometries: validGeom,
      containerBoxes: validBoxes,
    );
  }
}
