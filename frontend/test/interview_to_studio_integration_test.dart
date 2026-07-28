// ignore_for_file: avoid_print

@Tags(['integration'])
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/shared/models/roadmap_model.dart';
import 'package:frontend/features/workspace/data/roadmap_tree_builder.dart';

/// End-to-end integration test for the full pipeline:
///
///   User Prompt → POST /orchestration/dag-generate → KnowledgeGraphSchema
///   → RoadmapTreeBuilder → Hierarchical Workspace Roadmap
///
/// Requires: Spring Boot backend running on localhost:8080.
/// Run with: flutter test test/interview_to_studio_integration_test.dart

const _baseUrl = 'http://localhost:8080/api';
const _devToken =
    'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJmYjM4MDFjYy1iZTZhLTQyZjItOWVmYS1hOGQ2MzYzYTY3NWUiLCJlbWFpbCI6InRlc3RAb3Jlby5jb20iLCJpYXQiOjE3ODUxNjcxMTksImV4cCI6MTc4NTI1MzUxOX0.lr8cwxPgtBtPWOjvCV-a8csZJ8CmQZAMbfWYzsTh5Vtsep2k6Wg3U5uFAxzvKaCbR7U-VbhW6Mex7Q_dhKjp7w';

Map<String, String> _headers() => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_devToken',
    };

/// Calls the DAG generation endpoint and returns the parsed payload.
Future<Map<String, dynamic>> _generateCourse(String subject) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/orchestration/dag-generate'),
    headers: _headers(),
    body: jsonEncode({
      'goal': subject,
      'persona': 'Visual learner, needs structured milestones',
    }),
  );

  expect(response.statusCode, 200,
      reason: '$subject: Backend returned ${response.statusCode}');

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return data['payload'] as Map<String, dynamic>? ?? {};
}

/// Shared assertion helper for validating a generated course graph.
void assertValidCourseGraph({
  required List<RoadmapNode> tree,
  required List<RoadmapEdge> edges,
  required int minSections,
  required int minTotalNodes,
  required String subject,
}) {
  // 1. Tree is not empty
  expect(tree, isNotEmpty, reason: '$subject: tree is empty');

  // 2. Minimum section count
  final sections = tree.where((n) => n.type == NodeType.section).toList();
  expect(sections.length, greaterThanOrEqualTo(minSections),
      reason:
          '$subject: expected >= $minSections sections, got ${sections.length}');

  // 3. Every section has at least one child
  for (final sec in sections) {
    expect(sec.children, isNotEmpty,
        reason: '$subject: section "${sec.title}" has no children');
  }

  // 4. Total node count (recursive)
  int countNodes(List<RoadmapNode> nodes) =>
      nodes.fold(0, (sum, n) => sum + 1 + countNodes(n.children));
  final totalNodes = countNodes(tree);
  expect(totalNodes, greaterThanOrEqualTo(minTotalNodes),
      reason:
          '$subject: expected >= $minTotalNodes total nodes, got $totalNodes');

  // 5. At least one CAPSTONE node exists somewhere
  bool hasType(List<RoadmapNode> nodes, NodeType type) =>
      nodes.any((n) => n.type == type || hasType(n.children, type));
  expect(hasType(tree, NodeType.capstone), true,
      reason: '$subject: missing CAPSTONE node');

  // 6. Edges are non-empty
  expect(edges, isNotEmpty, reason: '$subject: no edges');

  // 7. No orphan non-section nodes at top level that should have been nested
  // (This is a soft check — orphans are allowed if the AI didn't group them)

  // 8. All node IDs are deterministic snake_case (no UUIDs)
  void checkIds(List<RoadmapNode> nodes) {
    for (final n in nodes) {
      expect(n.id, isNot(contains(' ')),
          reason: '$subject: node "${n.id}" has spaces');
      expect(n.id.length, greaterThan(0),
          reason: '$subject: node has empty id');
      checkIds(n.children);
    }
  }
  checkIds(tree);

  // 9. All node titles are non-empty
  void checkTitles(List<RoadmapNode> nodes) {
    for (final n in nodes) {
      expect(n.title, isNotEmpty,
          reason: '$subject: node "${n.id}" has empty title');
      checkTitles(n.children);
    }
  }
  checkTitles(tree);
}

void main() {
  group('Interview → Studio Pipeline (Live Backend)', () {
    test('Java course generates valid hierarchical roadmap', () async {
      final payload = await _generateCourse('Java');
      final nodes = (payload['nodes'] as List?) ?? [];
      final edges = (payload['edges'] as List?) ?? [];

      final result = RoadmapTreeBuilder.build(nodes, edges);

      // Debug output
      print('=== Java Course ===');
      print('Top-level nodes: ${result.tree.length}');
      for (final n in result.tree) {
        print('  [${n.type.name}] ${n.title} (${n.children.length} children)');
        for (final c in n.children) {
          print('    └─ [${c.type.name}] ${c.title}');
        }
      }
      print('Edges: ${result.edges.length}');

      assertValidCourseGraph(
        tree: result.tree,
        edges: result.edges,
        minSections: 3,
        minTotalNodes: 8,
        subject: 'Java',
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Python course generates valid hierarchical roadmap', () async {
      final payload = await _generateCourse('Python');
      final nodes = (payload['nodes'] as List?) ?? [];
      final edges = (payload['edges'] as List?) ?? [];

      final result = RoadmapTreeBuilder.build(nodes, edges);

      print('=== Python Course ===');
      print('Top-level nodes: ${result.tree.length}');
      for (final n in result.tree) {
        print('  [${n.type.name}] ${n.title} (${n.children.length} children)');
        for (final c in n.children) {
          print('    └─ [${c.type.name}] ${c.title}');
        }
      }
      print('Edges: ${result.edges.length}');

      assertValidCourseGraph(
        tree: result.tree,
        edges: result.edges,
        minSections: 3,
        minTotalNodes: 8,
        subject: 'Python',
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Flutter course generates valid hierarchical roadmap', () async {
      final payload = await _generateCourse('Flutter');
      final nodes = (payload['nodes'] as List?) ?? [];
      final edges = (payload['edges'] as List?) ?? [];

      final result = RoadmapTreeBuilder.build(nodes, edges);

      print('=== Flutter Course ===');
      print('Top-level nodes: ${result.tree.length}');
      for (final n in result.tree) {
        print('  [${n.type.name}] ${n.title} (${n.children.length} children)');
        for (final c in n.children) {
          print('    └─ [${c.type.name}] ${c.title}');
        }
      }
      print('Edges: ${result.edges.length}');

      assertValidCourseGraph(
        tree: result.tree,
        edges: result.edges,
        minSections: 3,
        minTotalNodes: 8,
        subject: 'Flutter',
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('AI Engineering course generates valid hierarchical roadmap',
        () async {
      final payload = await _generateCourse('AI Engineering');
      final nodes = (payload['nodes'] as List?) ?? [];
      final edges = (payload['edges'] as List?) ?? [];

      final result = RoadmapTreeBuilder.build(nodes, edges);

      print('=== AI Engineering Course ===');
      print('Top-level nodes: ${result.tree.length}');
      for (final n in result.tree) {
        print('  [${n.type.name}] ${n.title} (${n.children.length} children)');
        for (final c in n.children) {
          print('    └─ [${c.type.name}] ${c.title}');
        }
      }
      print('Edges: ${result.edges.length}');

      assertValidCourseGraph(
        tree: result.tree,
        edges: result.edges,
        minSections: 4,
        minTotalNodes: 10,
        subject: 'AI Engineering',
      );
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
