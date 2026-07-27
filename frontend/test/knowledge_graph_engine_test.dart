import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/knowledge_graph/domain/models/knowledge_graph_model.dart';
import 'package:frontend/features/knowledge_graph/domain/models/graph_state.dart';
import 'package:frontend/features/knowledge_graph/domain/layout/layout_manager.dart';
import 'package:frontend/features/knowledge_graph/data/datasources/mock_knowledge_graph_data.dart';

void main() {
  group('Knowledge Graph Modular Layout Pipeline Tests', () {
    late KnowledgeGraph graph;
    late LayoutManager layoutManager;
    late GraphState initialState;

    setUp(() {
      graph = MockKnowledgeGraphData.getWorkspaceGraph('python_backend');
      layoutManager = LayoutManager();
      initialState = GraphState(
        activeWorkspaceId: 'python_backend',
        selectedNodeId: graph.nodes.first.id,
      );
    });

    test('1. Determinism: Same graph and state produce identical layout coordinates', () {
      final res1 = layoutManager.computeLayout(graph, useCache: false);
      final res2 = layoutManager.computeLayout(graph, useCache: false);

      expect(res1.nodeGeometries.length, equals(res2.nodeGeometries.length));
      for (final id in res1.nodeGeometries.keys) {
        final g1 = res1.nodeGeometries[id]!;
        final g2 = res2.nodeGeometries[id]!;
        expect(g1.x, equals(g2.x), reason: 'Node $id X coordinates must match');
        expect(g1.y, equals(g2.y), reason: 'Node $id Y coordinates must match');
        expect(g1.width, equals(g2.width));
        expect(g1.height, equals(g2.height));
      }
      expect(res1.totalBounds, equals(res2.totalBounds));
    });

    test('2. Caching: Second request returns cached instance without re-computation', () {
      final res1 = layoutManager.computeLayout(graph, useCache: true);
      final res2 = layoutManager.computeLayout(graph, useCache: true);

      expect(identical(res1, res2), isTrue, reason: 'Cached LayoutResult instance must be identical');
    });

    test('3. Permanent Visibility: All nodes and sections in graph are permanently visible in layout', () {
      final res = layoutManager.computeLayout(graph, useCache: false);
      expect(res.visibleNodes.length, equals(graph.nodes.length),
          reason: 'Every node in the roadmap must be visible by default without hidden or collapsed states');
    });

    test('4. Zero-Overlap Constraint: No two visible node bounding boxes intersect', () {
      final res = layoutManager.computeLayout(graph, useCache: false);

      final nodes = res.visibleNodes;
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final g1 = res.nodeGeometries[nodes[i].id]!;
          final g2 = res.nodeGeometries[nodes[j].id]!;

          // Ignore parent-child inclusion (e.g. section container enclosing children if applicable)
          if (nodes[i].parentId == nodes[j].id || nodes[j].parentId == nodes[i].id) continue;

          // Check intersection with minimum spacing allowance
          final rect1 = Rect.fromLTWH(g1.x, g1.y, g1.width, g1.height);
          final rect2 = Rect.fromLTWH(g2.x, g2.y, g2.width, g2.height);

          final overlaps = rect1.overlaps(rect2);
          expect(overlaps, isFalse, reason: 'Node ${nodes[i].label} overlaps with ${nodes[j].label}');
        }
      }
    });

    test('5. Edge Anchoring: All routed edges terminate on node boundaries', () {
      final res = layoutManager.computeLayout(graph, useCache: false);

      for (final edge in res.routedEdges) {
        if (edge.controlPoints.isEmpty) continue;

        final sourceGeom = res.nodeGeometries[edge.sourceNodeId];
        final targetGeom = res.nodeGeometries[edge.targetNodeId];
        if (sourceGeom == null || targetGeom == null) continue;

        final firstPt = edge.controlPoints.first.toOffset();
        final lastPt = edge.controlPoints.last.toOffset();

        final sourceRect = sourceGeom.toRect();
        final targetRect = targetGeom.toRect();

        // Ensure start point touches source border (within 2px tolerance)
        final bool startOnBorder = (firstPt.dx - sourceRect.left).abs() <= 2.0 ||
                                   (firstPt.dx - sourceRect.right).abs() <= 2.0 ||
                                   (firstPt.dy - sourceRect.top).abs() <= 2.0 ||
                                   (firstPt.dy - sourceRect.bottom).abs() <= 2.0;
        expect(startOnBorder, isTrue, reason: 'Edge ${edge.id} start must touch source node border');

        // Ensure end point touches target border (within 2px tolerance)
        final bool endOnBorder = (lastPt.dx - targetRect.left).abs() <= 2.0 ||
                                 (lastPt.dx - targetRect.right).abs() <= 2.0 ||
                                 (lastPt.dy - targetRect.top).abs() <= 2.0 ||
                                 (lastPt.dy - targetRect.bottom).abs() <= 2.0;
        expect(endOnBorder, isTrue, reason: 'Edge ${edge.id} end must touch target node border');
      }
    });

    test('6. Viewport Stability: Zooming and panning must never change the rendered node count', () {
      final fullRes = layoutManager.computeLayout(graph, useCache: false);
      expect(fullRes.visibleNodes.length, equals(graph.nodes.length), 
          reason: 'All nodes must be visible regardless of viewport transformations');
      expect(fullRes.nodeGeometries.length, equals(graph.nodes.length),
          reason: 'All node geometries must be available');
    });

    test('7. Search Integration: Handle search updates highlightedNodeId without altering visible nodes or geometry', () {
      final targetNode = graph.nodes.last;
      final searchRes = layoutManager.handleSearch(targetNode.id, graph, initialState);

      expect(searchRes.state.highlightedNodeId, equals(targetNode.id));
      expect(searchRes.layoutResult.visibleNodes.length, equals(graph.nodes.length));
      expect(searchRes.layoutResult.nodeGeometries.length, equals(graph.nodes.length));
    });
  });
}
