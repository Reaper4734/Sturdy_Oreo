import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/shared/models/workspace_model.dart';
import 'package:frontend/shared/models/roadmap_model.dart';
import 'package:frontend/shared/models/micro_interview_model.dart';
import 'roadmap_tree_builder.dart';

class HttpWorkspaceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<WorkspaceModel> createWorkspaceFromCourse(String courseTitle, {String persona = 'Visual learner'}) async {
    final response = await _apiClient.post('/orchestration/dag-generate', body: {
      'goal': courseTitle,
      'persona': persona,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final payload = data['payload'] ?? {};
      final nodes = (payload['nodes'] as List?) ?? [];
      final edgesList = (payload['edges'] as List?) ?? [];

      final result = RoadmapTreeBuilder.build(nodes, edgesList);
      final roadmapNodes = result.tree;
      final roadmapEdges = result.edges;

      return WorkspaceModel(
        id: data['trackId'] ?? 'ws_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_priyaj', // Dummy user
        title: payload['courseTitle'] ?? payload['goal'] ?? courseTitle,
        subject: courseTitle,
        difficulty: payload['difficulty'] ?? 'Intermediate',
        createdAt: DateTime.now(),
        lastOpened: DateTime.now(),
        progressPercent: 0.0,
        activeLearningContext: courseTitle,
        flashcardCount: 0,
        roadmapNodeCount: roadmapNodes.length,
        accentColor: const Color(0xFF67E8F9),
        roadmap: roadmapNodes,
        edges: roadmapEdges,
        isCourseConfirmed: false,
        chatHistory: [
          ChatMessage(
            id: 'init_msg',
            sender: 'AI',
            text: 'Here is your generated roadmap. Do you want to continue with it or customize?',
            timestamp: DateTime.now(),
          )
        ],
      );
    } else {
      throw Exception('Failed to generate workspace: ${response.statusCode}');
    }
  }

  Future<WorkspaceModel> updateRoadmap(WorkspaceModel currentWs, String userRequest) async {
    // Construct a representation of currentDag from currentWs.roadmap
    final nodesJson = currentWs.roadmap.map((n) => {
      'id': n.id,
      'title': n.title,
      'type': n.type.name,
      'prereqs': [], // Ignored since we are using edges
      'rationale': n.subtitle ?? '',
      'alternatives': []
    }).toList();

    final edgesJson = currentWs.edges.map((e) => {
      'from': e.from,
      'to': e.to
    }).toList();

    final currentDag = {
      'track_id': currentWs.id,
      'courseTitle': currentWs.title,
      'graphType': 'DAG',
      'nodes': nodesJson,
      'edges': edgesJson
    };

    final response = await _apiClient.post('/orchestration/roadmap/update', body: {
      'request': userRequest,
      'currentDag': currentDag
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final payload = data['payload'] ?? {};
      final nodes = (payload['nodes'] as List?) ?? [];
      final edgesList = (payload['edges'] as List?) ?? [];

      final result = RoadmapTreeBuilder.build(nodes, edgesList);
      final roadmapNodes = result.tree;
      final roadmapEdges = result.edges;

      currentWs.roadmap = roadmapNodes;
      currentWs.edges = roadmapEdges;
      currentWs.roadmapNodeCount = roadmapNodes.length;
      return currentWs;
    } else {
      throw Exception('Failed to update roadmap: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> searchVideos(String topic) async {
    final response = await _apiClient.get('/search/videos?topic=${Uri.encodeComponent(topic)}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to search videos: ${response.statusCode}');
    }
  }
}

final httpWorkspaceRepositoryProvider = Provider((ref) => HttpWorkspaceRepository());
