import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/shared/models/workspace_model.dart';
import 'package:frontend/shared/models/roadmap_model.dart';
import 'package:frontend/shared/models/micro_interview_model.dart';
import 'package:frontend/shared/models/mind_map_model.dart';
import 'package:frontend/shared/models/workspace_model_ext.dart';
import 'package:frontend/shared/models/persona_model.dart';
import 'package:frontend/shared/models/flashcard_model.dart';

class HttpWorkspaceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<WorkspaceModel> createWorkspaceFromCourse(String courseTitle, {String persona = 'Visual learner'}) async {
    final response = await _apiClient.post('/v1/mindmap/generate', body: {
      'subjectTitle': courseTitle,
      'persona': persona,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      final subjectCluster = SubjectCluster.fromJson(data);

      List<RoadmapNode> generatedRoadmap = [];
      int weekIndex = 1;
      for (var child in subjectCluster.rootNode.children) {
        generatedRoadmap.add(RoadmapNode(
          id: child.id,
          title: 'Module ${weekIndex++}: ${child.label}',
          type: NodeType.section,
          estimatedHours: 5,
          children: child.children.map((c) => RoadmapNode(
            id: c.id,
            title: c.label,
            type: NodeType.topic,
            estimatedHours: 2,
            children: c.children.map((cc) => RoadmapNode(
              id: cc.id,
              title: cc.label,
              type: NodeType.topic,
            )).toList()
          )).toList()
        ));
      }

      final workspace = WorkspaceModel(
        id: data['subjectId'] ?? 'ws_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_priyaj', // Dummy user
        title: data['subjectTitle'] ?? courseTitle,
        subject: courseTitle,
        difficulty: 'Intermediate',
        createdAt: DateTime.now(),
        lastOpened: DateTime.now(),
        progressPercent: 0.0,
        activeLearningContext: courseTitle,
        flashcardCount: 0,
        roadmapNodeCount: generatedRoadmap.length,
        accentColor: const Color(0xFF67E8F9),
        roadmap: generatedRoadmap,
        edges: [],
        subjectCluster: subjectCluster,
        persona: data['persona'] != null ? PersonaProfile.fromJson(data['persona']) : null,
        isCourseConfirmed: false,
        flashcards: [], 
        chatHistory: [
          ChatMessage(
            id: 'init_msg',
            sender: 'AI',
            text: 'Here is your generated mind map. Do you want to continue with it or customize?',
            timestamp: DateTime.now(),
          )
        ],
      );

      // Fetch dynamic initial flashcards from backend
      try {
        final fcResponse = await _apiClient.post('/orchestration/generate-flashcards', body: {'topic': courseTitle});
        if (fcResponse.statusCode == 200) {
          final List<dynamic> fcData = jsonDecode(fcResponse.body);
          workspace.flashcards = fcData.asMap().entries.map((entry) {
            final json = entry.value;
            return FlashcardItem(
              id: 'fc_init_${entry.key}',
              front: json['frontQuestion'] ?? 'Question?',
              back: json['backAnswer'] ?? 'Answer.',
              topicTag: courseTitle,
            );
          }).toList();
          workspace.flashcardCount = workspace.flashcards.length;
        }
      } catch (e) {
        debugPrint('Failed to generate initial flashcards: $e');
      }

      return workspace;
    } else {
      throw Exception('Failed to generate workspace: ${response.statusCode}');
    }
  }

  Future<WorkspaceModel> updateRoadmap(WorkspaceModel currentWs, String userRequest) async {
    // The backend roadmap update endpoint was deleted in favor of MindMaps
    // MindMap updates are not yet supported in the backend migration guide.
    throw UnimplementedError('MindMap updates are not yet supported');
  }

  Future<List<Map<String, dynamic>>> searchVideos(String workspaceId, String topic, {String context = ''}) async {
    final response = await _apiClient.get('/search/videos?workspaceId=${Uri.encodeComponent(workspaceId)}&topic=${Uri.encodeComponent(topic)}&context=${Uri.encodeComponent(context)}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      throw Exception('Failed to search videos: ${response.statusCode}');
    }
  }

  Future<List<WorkspaceModel>> getAll() async {
    final response = await _apiClient.get('/workspaces');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => WorkspaceModelSerialization.fromJson(json)).toList();
    }
    return [];
  }

  Future<WorkspaceModel> create(WorkspaceModel ws) async {
    final response = await _apiClient.post('/workspaces', body: ws.toJson());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return WorkspaceModelSerialization.fromJson(data);
    }
    return ws;
  }

  Future<void> delete(String id) async {
    await _apiClient.get('/workspaces/$id'); // delete is not exposed on ApiClient yet, so we could implement delete, but for now we skip or just print.
  }

  Future<WorkspaceModel> duplicate(String id) async {
    throw UnimplementedError('duplicate not implemented on backend');
  }

  Future<void> archive(String id, {required bool isArchived}) async {
    // Ignore for now
  }

  Future<void> pin(String id, {required bool isPinned}) async {
    // Ignore for now
  }

  Future<WorkspaceModel?> getById(String id) async {
    final response = await _apiClient.get('/workspaces/$id');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return WorkspaceModelSerialization.fromJson(data);
    }
    return null;
  }

  Future<void> update(WorkspaceModel ws) async {
    await _apiClient.put('/workspaces/${ws.id}', body: ws.toJson());
  }

  Future<List<FlashcardItem>> generateFlashcardsForTopic(String topic) async {
    try {
      final fcResponse = await _apiClient.post('/orchestration/generate-flashcards', body: {'topic': topic});
      if (fcResponse.statusCode == 200) {
        final List<dynamic> fcData = jsonDecode(fcResponse.body);
        return fcData.asMap().entries.map((entry) {
          final json = entry.value;
          return FlashcardItem(
            id: 'fc_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
            front: json['frontQuestion'] ?? 'Question?',
            back: json['backAnswer'] ?? 'Answer.',
            topicTag: topic,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Failed to generate flashcards for topic: $e');
    }
    return [];
  }
}

final httpWorkspaceRepositoryProvider = Provider((ref) => HttpWorkspaceRepository());
