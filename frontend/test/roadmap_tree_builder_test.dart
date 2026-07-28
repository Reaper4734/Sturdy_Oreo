import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/models/roadmap_model.dart';
import 'package:frontend/features/workspace/data/roadmap_tree_builder.dart';

void main() {
  group('RoadmapTreeBuilder', () {
    test('groups TOPIC children under their parent SECTION', () {
      final nodes = [
        {'id': 'python_foundations', 'title': 'Python Foundations', 'type': 'SECTION', 'rationale': 'Core language basics'},
        {'id': 'variables', 'title': 'Variables', 'type': 'TOPIC', 'rationale': 'Learn variable assignment'},
        {'id': 'loops', 'title': 'Loops', 'type': 'TOPIC', 'rationale': 'Iteration basics'},
        {'id': 'python_oop', 'title': 'Python OOP', 'type': 'SECTION', 'rationale': 'Object-oriented programming'},
        {'id': 'classes', 'title': 'Classes', 'type': 'TOPIC', 'rationale': 'Class definition'},
      ];
      final edges = [
        {'from': 'python_foundations', 'to': 'variables'},
        {'from': 'python_foundations', 'to': 'loops'},
        {'from': 'python_oop', 'to': 'classes'},
        {'from': 'python_foundations', 'to': 'python_oop'}, // section-to-section edge (ordering, not containment)
      ];

      final result = RoadmapTreeBuilder.build(nodes, edges);

      // Top-level should contain the two SECTION nodes
      expect(result.tree.length, 2);
      expect(result.tree[0].id, 'python_foundations');
      expect(result.tree[1].id, 'python_oop');

      // python_foundations should have 2 children: variables, loops
      expect(result.tree[0].children.length, 2);
      expect(result.tree[0].children[0].id, 'variables');
      expect(result.tree[0].children[1].id, 'loops');

      // python_oop should have 1 child: classes
      expect(result.tree[1].children.length, 1);
      expect(result.tree[1].children[0].id, 'classes');
    });

    test('orphan nodes without a parent SECTION stay top-level', () {
      final nodes = [
        {'id': 'sec_a', 'title': 'Section A', 'type': 'SECTION'},
        {'id': 'topic_1', 'title': 'Topic 1', 'type': 'TOPIC'},
        {'id': 'capstone_final', 'title': 'Final Capstone', 'type': 'CAPSTONE'},
      ];
      final edges = [
        {'from': 'sec_a', 'to': 'topic_1'},
      ];

      final result = RoadmapTreeBuilder.build(nodes, edges);

      // sec_a (with topic_1 as child) + capstone_final (orphan) = 2 top-level
      expect(result.tree.length, 2);
      final topIds = result.tree.map((n) => n.id).toSet();
      expect(topIds.contains('sec_a'), true);
      expect(topIds.contains('capstone_final'), true);
      expect(topIds.contains('topic_1'), false);

      final secA = result.tree.firstWhere((n) => n.id == 'sec_a');
      expect(secA.children.length, 1);
      expect(secA.children[0].id, 'topic_1');
    });

    test('empty nodes and edges returns empty tree', () {
      final result = RoadmapTreeBuilder.build([], []);
      expect(result.tree, isEmpty);
      expect(result.edges, isEmpty);
    });

    test('all flat nodes with no edges renders all as top-level', () {
      final nodes = [
        {'id': 'a', 'title': 'A', 'type': 'TOPIC'},
        {'id': 'b', 'title': 'B', 'type': 'TOPIC'},
        {'id': 'c', 'title': 'C', 'type': 'PROJECT'},
      ];

      final result = RoadmapTreeBuilder.build(nodes, []);

      expect(result.tree.length, 3);
      for (final node in result.tree) {
        expect(node.children, isEmpty);
      }
    });

    test('edges between non-SECTION nodes do not create parent-child', () {
      final nodes = [
        {'id': 'topic_a', 'title': 'Topic A', 'type': 'TOPIC'},
        {'id': 'topic_b', 'title': 'Topic B', 'type': 'TOPIC'},
      ];
      final edges = [
        {'from': 'topic_a', 'to': 'topic_b'},
      ];

      final result = RoadmapTreeBuilder.build(nodes, edges);

      expect(result.tree.length, 2);
      expect(result.tree[0].children, isEmpty);
      expect(result.tree[1].children, isEmpty);
    });

    test('correctly parses all NodeType enums', () {
      final nodes = [
        {'id': 'n1', 'title': 'S', 'type': 'SECTION'},
        {'id': 'n2', 'title': 'T', 'type': 'TOPIC'},
        {'id': 'n3', 'title': 'P', 'type': 'PROJECT'},
        {'id': 'n4', 'title': 'A', 'type': 'ASSESSMENT'},
        {'id': 'n5', 'title': 'C', 'type': 'CAPSTONE'},
        {'id': 'n6', 'title': 'U', 'type': 'unknown_type'},
      ];

      final result = RoadmapTreeBuilder.build(nodes, []);

      final typeMap = {for (var n in result.tree) n.id: n.type};
      expect(typeMap['n1'], NodeType.section);
      expect(typeMap['n2'], NodeType.topic);
      expect(typeMap['n3'], NodeType.project);
      expect(typeMap['n4'], NodeType.assessment);
      expect(typeMap['n5'], NodeType.capstone);
      expect(typeMap['n6'], NodeType.topic); // fallback default
    });

    test('edges with missing node IDs are silently ignored', () {
      final nodes = [
        {'id': 'sec', 'title': 'Section', 'type': 'SECTION'},
        {'id': 'topic', 'title': 'Topic', 'type': 'TOPIC'},
      ];
      final edges = [
        {'from': 'sec', 'to': 'topic'},
        {'from': 'sec', 'to': 'nonexistent_node'},
        {'from': 'ghost', 'to': 'topic'},
      ];

      final result = RoadmapTreeBuilder.build(nodes, edges);

      expect(result.tree.length, 1);
      expect(result.tree[0].children.length, 1);
      expect(result.tree[0].children[0].id, 'topic');
    });

    test('real-world AI output: AI Engineering course hierarchy', () {
      final nodes = [
        {'id': 'ai_foundations', 'title': 'AI Foundations', 'type': 'SECTION', 'rationale': 'Core math', 'estimatedHours': 8, 'difficulty': 'BEGINNER'},
        {'id': 'linear_algebra', 'title': 'Linear Algebra', 'type': 'TOPIC'},
        {'id': 'calculus_basics', 'title': 'Calculus', 'type': 'TOPIC'},
        {'id': 'math_quiz', 'title': 'Math Quiz', 'type': 'ASSESSMENT'},
        {'id': 'python_ecosystem', 'title': 'Python Ecosystem', 'type': 'SECTION', 'estimatedHours': 10},
        {'id': 'numpy_pandas', 'title': 'NumPy & Pandas', 'type': 'TOPIC'},
        {'id': 'pytorch_intro', 'title': 'PyTorch', 'type': 'TOPIC'},
        {'id': 'data_project', 'title': 'Data Pipeline', 'type': 'PROJECT'},
        {'id': 'capstone_ai', 'title': 'AI Capstone', 'type': 'CAPSTONE'},
      ];
      final edges = [
        {'from': 'ai_foundations', 'to': 'linear_algebra'},
        {'from': 'ai_foundations', 'to': 'calculus_basics'},
        {'from': 'ai_foundations', 'to': 'math_quiz'},
        {'from': 'python_ecosystem', 'to': 'numpy_pandas'},
        {'from': 'python_ecosystem', 'to': 'pytorch_intro'},
        {'from': 'python_ecosystem', 'to': 'data_project'},
        {'from': 'ai_foundations', 'to': 'python_ecosystem'}, // section ordering
        {'from': 'python_ecosystem', 'to': 'capstone_ai'},
      ];

      final result = RoadmapTreeBuilder.build(nodes, edges);

      final topIds = result.tree.map((n) => n.id).toSet();
      expect(topIds.contains('ai_foundations'), true);
      expect(topIds.contains('python_ecosystem'), true);

      final aiFoundations = result.tree.firstWhere((n) => n.id == 'ai_foundations');
      expect(aiFoundations.children.length, 3);

      final pyEco = result.tree.firstWhere((n) => n.id == 'python_ecosystem');
      final pyChildIds = pyEco.children.map((c) => c.id).toSet();
      expect(pyChildIds.contains('numpy_pandas'), true);
      expect(pyChildIds.contains('pytorch_intro'), true);
      expect(pyChildIds.contains('data_project'), true);
      expect(pyChildIds.contains('capstone_ai'), true);

      expect(topIds.contains('linear_algebra'), false);
      expect(topIds.contains('numpy_pandas'), false);
    });
  });
}
