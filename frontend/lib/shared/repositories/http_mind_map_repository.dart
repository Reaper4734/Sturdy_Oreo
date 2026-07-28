import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import '../models/mind_map_model.dart';

class HttpMindMapRepository {
  final ApiClient _apiClient = ApiClient();

  Future<SubjectCluster> getSubjectCluster(String subject) async {
    final response = await _apiClient.post('/resource-map/generate', body: {
      'subject': subject,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      final nodes = (data['nodes'] as List<dynamic>).map((n) => n as Map<String, dynamic>).toList();
      final edges = (data['edges'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();

      // Find root node (assuming first node is root or find one with no incoming edges)
      Map<String, dynamic>? rootMap;
      if (nodes.isNotEmpty) {
        rootMap = nodes.firstWhere((n) => n['type'] == 'core', orElse: () => nodes.first);
      }

      ConceptNode buildTree(Map<String, dynamic> currentMap, int depth) {
        final id = currentMap['id'] as String;
        final label = currentMap['title'] as String;
        
        // Find children
        final childEdges = edges.where((e) => e['sourceId'] == id || e['source'] == id).toList();
        final childrenNodes = <ConceptNode>[];
        
        for (var edge in childEdges) {
          final targetId = edge['targetId'] ?? edge['target'];
          final childMap = nodes.firstWhere((n) => n['id'] == targetId, orElse: () => <String, dynamic>{});
          if (childMap.isNotEmpty) {
            childrenNodes.add(buildTree(childMap, depth + 1));
          }
        }

        return ConceptNode(
          id: id,
          label: label,
          depthLevel: depth,
          isTerminal: childrenNodes.isEmpty,
          children: childrenNodes,
        );
      }

      ConceptNode rootNode = rootMap != null 
        ? buildTree(rootMap, 0)
        : ConceptNode(id: 'root', label: 'Root');

      return SubjectCluster(
        subjectId: 'cluster_${DateTime.now().millisecondsSinceEpoch}',
        subjectTitle: data['subject'] ?? subject,
        rootNode: rootNode,
      );
    } else {
      throw Exception('Failed to generate mind map: ${response.statusCode}');
    }
  }
}

final httpMindMapRepositoryProvider = Provider((ref) => HttpMindMapRepository());
