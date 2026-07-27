import 'dart:ui';
import '../models/knowledge_graph_model.dart';
import '../models/graph_state.dart';
import '../models/graph_theme.dart';
import '../models/layout_result.dart';
import 'layered_layout_algorithm.dart';
import 'container_layout_engine.dart';
import 'overlap_resolver.dart';
import 'constraint_validator.dart';
import 'edge_router.dart';
import 'layout_cache.dart';

/// Master Layout Manager orchestrating the modular layout pipeline.
/// Each stage has a single responsibility.
class LayoutManager {
  final LayoutCache _cache = LayoutCache();

  /// Executes the layout pipeline deterministically for an immutable knowledge graph.
  LayoutResult computeLayout(
    KnowledgeGraph graph, {
    GraphTheme theme = GraphTheme.defaultTheme,
    bool useCache = true,
  }) {
    if (useCache) {
      final cached = _cache.get(graph.graphId);
      if (cached != null) return cached;
    }

    // Stage 1 to 4: Immutable Graph passed directly (All nodes and edges are permanently visible)
    // Stage 5: Layered Layout Algorithm assigns vertical layered ranks and columns
    final initialGeometries = LayeredLayoutAlgorithm.assignLayers(
      graph.nodes,
      theme,
    );

    // Stage 6: Container Layout Engine auto-sizes group containers and centers parents
    final containerOutput = ContainerLayoutEngine.computeContainers(
      graph.nodes,
      initialGeometries,
      theme,
    );

    // Stage 7: Overlap Resolver eliminates node and container bounding box intersections
    final overlapOutput = OverlapResolver.resolveOverlaps(
      graph.nodes,
      containerOutput.geometries,
      containerOutput.containerBoxes,
      theme,
    );

    // Stage 8: Constraint Validator enforces all mandatory rules and runs corrections
    final validatedOutput = ConstraintValidator.validateAndCorrect(
      graph.nodes,
      graph.edges,
      overlapOutput.geometries,
      overlapOutput.containerBoxes,
      theme,
    );

    // Stage 9: Edge Router resolves ports and routes clean paths
    final routedEdges = EdgeRouter.routeEdges(
      graph.edges,
      validatedOutput.geometries,
      theme,
    );

    // Calculate total bounding rect
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final geom in validatedOutput.geometries.values) {
      if (geom.x < minX) minX = geom.x;
      if (geom.y < minY) minY = geom.y;
      if (geom.x + geom.width > maxX) maxX = geom.x + geom.width;
      if (geom.y + geom.height > maxY) maxY = geom.y + geom.height;
    }
    for (final box in validatedOutput.containerBoxes) {
      if (box.bounds.left < minX) minX = box.bounds.left;
      if (box.bounds.top < minY) minY = box.bounds.top;
      if (box.bounds.right > maxX) maxX = box.bounds.right;
      if (box.bounds.bottom > maxY) maxY = box.bounds.bottom;
    }
    if (minX == double.infinity) {
      minX = 0;
      minY = 0;
      maxX = 1200;
      maxY = 1000;
    }

    final double padding = 100.0;
    final double offsetX = -minX + padding;
    final double offsetY = -minY + padding;

    // Shift geometries
    final Map<String, NodeGeometry> normalizedGeometries = {};
    for (final entry in validatedOutput.geometries.entries) {
      normalizedGeometries[entry.key] = entry.value.copyWith(
        x: entry.value.x + offsetX,
        y: entry.value.y + offsetY,
      );
    }

    // Shift container boxes
    final List<ContainerBox> normalizedBoxes = validatedOutput.containerBoxes.map((b) {
      return ContainerBox(
        id: b.id,
        bounds: b.bounds.shift(Offset(offsetX, offsetY)),
        label: b.label,
        groupType: b.groupType,
        childNodeIds: b.childNodeIds,
      );
    }).toList();

    // Shift routed edges
    final List<GraphEdge> normalizedEdges = routedEdges.map((e) {
      return e.copyWith(
        controlPoints: e.controlPoints.map((p) => ControlPoint(p.x + offsetX, p.y + offsetY)).toList(),
      );
    }).toList();

    // The normalized total bounds will start at 0, 0
    final totalBounds = Rect.fromLTRB(
      0, 
      0, 
      maxX - minX + (padding * 2), 
      maxY - minY + (padding * 2)
    );

    // Stage 10: Produce LayoutResult
    final result = LayoutResult(
      nodeGeometries: normalizedGeometries,
      visibleNodes: graph.nodes,
      routedEdges: normalizedEdges,
      containerBoxes: normalizedBoxes,
      totalBounds: totalBounds,
      isValidated: true,
    );

    if (useCache) {
      _cache.put(graph.graphId, result);
    }

    return result;
  }

  /// Handles search query integration: updates highlight state on cached immutable layout.
  SearchResult handleSearch(
    String targetNodeId,
    KnowledgeGraph graph,
    GraphState state, {
    GraphTheme theme = GraphTheme.defaultTheme,
  }) {
    final newState = state.copyWith(
      highlightedNodeId: targetNodeId,
    );

    // Get cached immutable layout (never recalculates on search)
    final result = computeLayout(graph, theme: theme, useCache: true);

    return SearchResult(state: newState, layoutResult: result);
  }

  void invalidateCache(String graphId) {
    _cache.invalidate(graphId);
  }
}

class SearchResult {
  final GraphState state;
  final LayoutResult layoutResult;

  const SearchResult({required this.state, required this.layoutResult});
}
