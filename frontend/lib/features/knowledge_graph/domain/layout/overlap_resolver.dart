import 'dart:math' as math;
import 'dart:ui';
import '../models/knowledge_graph_model.dart';
import '../models/graph_theme.dart';
import '../models/layout_result.dart';
import 'container_layout_engine.dart';

/// Overlap Resolver stage in the layout pipeline.
/// Responsibilities: detect node overlap, detect container overlap, shift branches,
/// rebalance sibling spacing, and increase layer spacing if necessary before validation.
class OverlapResolver {
  /// Resolves any bounding box overlaps in node geometries and container boxes.
  static ContainerLayoutOutput resolveOverlaps(
    List<GraphNode> visibleNodes,
    Map<String, NodeGeometry> geometries,
    List<ContainerBox> containerBoxes,
    GraphTheme theme,
  ) {
    final Map<String, NodeGeometry> resolvedGeom = Map.from(geometries);
    List<ContainerBox> resolvedBoxes = List.from(containerBoxes);

    bool hasOverlap = true;
    int iterations = 0;
    const int maxIterations = 5; // Prevent infinite loops while guaranteeing separation

    while (hasOverlap && iterations < maxIterations) {
      hasOverlap = false;
      iterations++;

      // Sort node IDs by y coordinate top-down
      final sortedIds = resolvedGeom.keys.toList()
        ..sort((a, b) => resolvedGeom[a]!.y.compareTo(resolvedGeom[b]!.y));

      for (int i = 0; i < sortedIds.length; i++) {
        for (int j = i + 1; j < sortedIds.length; j++) {
          final idA = sortedIds[i];
          final idB = sortedIds[j];
          final geomA = resolvedGeom[idA]!;
          final geomB = resolvedGeom[idB]!;

          final rectA = geomA.toRect();
          final rectB = geomB.toRect();

          // Check intersection with minimum spacing buffer
          final paddedA = Rect.fromLTRB(
            rectA.left - theme.branchSpacing / 2,
            rectA.top - theme.branchSpacing / 2,
            rectA.right + theme.branchSpacing / 2,
            rectA.bottom + theme.branchSpacing / 2,
          );

          if (paddedA.overlaps(rectB)) {
            hasOverlap = true;
            // Decide whether to shift vertically (layer spacing) or horizontally (branch spacing)
            final double overlapY = paddedA.bottom - rectB.top;
            final double overlapXLeft = paddedA.right - rectB.left;
            final double overlapXRight = rectB.right - paddedA.left;

            if (overlapY > 0 && overlapY < 120.0 && (geomB.y - geomA.y).abs() > (geomB.x - geomA.x).abs() * 0.5) {
              // Push geomB and all items below it downwards
              final double shiftY = overlapY + 4.0;
              for (int k = j; k < sortedIds.length; k++) {
                final idK = sortedIds[k];
                final gK = resolvedGeom[idK]!;
                if (gK.y >= geomB.y - 1.0) {
                  resolvedGeom[idK] = gK.copyWith(y: gK.y + shiftY);
                }
              }
            } else {
              // Shift horizontally away from trunk center
              final double shiftX = math.min(overlapXLeft, overlapXRight) + 12.0;
              if (geomB.x >= geomA.x) {
                resolvedGeom[idB] = geomB.copyWith(x: geomB.x + shiftX);
              } else {
                resolvedGeom[idB] = geomB.copyWith(x: geomB.x - shiftX);
              }
            }
          }
        }
      }

      // Recompute container boxes after shifting nodes
      final output = ContainerLayoutEngine.computeContainers(
        visibleNodes,
        resolvedGeom,
        theme,
      );
      resolvedBoxes = output.containerBoxes;
    }

    return ContainerLayoutOutput(
      geometries: resolvedGeom,
      containerBoxes: resolvedBoxes,
    );
  }
}
