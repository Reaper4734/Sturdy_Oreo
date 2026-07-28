import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import '../models/micro_interview_model.dart';
import '../services/file_picker_service.dart';

class HttpInterviewRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ChatMessage> sendUserResponse(String text, String history, {List<AttachedFileModel>? files, String? workspaceRoadmapJson}) async {
    // If files/diagrams are attached, use the canvas-explain endpoint
    if (files != null && files.isNotEmpty) {
      return explain(text, files.first);
    }

    if (workspaceRoadmapJson != null) {
      final response = await _apiClient.post('/orchestration/workspace-chat', body: {
        'message': text,
        'history': history,
        'roadmap': workspaceRoadmapJson,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['aiResponse'] ?? "I didn't understand that.";
        final updatedRoadmap = data['updatedRoadmap'];
        return ChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'AI',
          text: aiResponse,
          metadata: updatedRoadmap != null ? {'updatedRoadmap': updatedRoadmap} : null,
        );
      } else {
        throw Exception('Failed to send workspace chat: ${response.statusCode}');
      }
    }

    final response = await _apiClient.post('/orchestration/interview', body: {
      'message': text,
      'history': history,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final replyToUser = data['reply_to_user'] ?? data['replyToUser'] ?? "I didn't understand that.";
      final optionsRaw = data['options'] as List<dynamic>?;
      final internalStateRaw = data['internal_state'] ?? data['internalState'];
      final Map<String, dynamic>? internalState = internalStateRaw != null ? Map<String, dynamic>.from(internalStateRaw) : null;
      
      final options = optionsRaw?.map((e) => e.toString()).toList() ?? [];

      return ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'AI',
        text: replyToUser,
        options: options.isNotEmpty ? options : null,
        attachments: [], // Backend doesn't return files yet
        metadata: internalState, // Store persona details for DAG generation
      );
    } else {
      throw Exception('Failed to send interview message: ${response.statusCode}');
    }
  }
  Future<ChatMessage> explain(String doubt, AttachedFileModel file) async {
    final response = await _apiClient.post('/orchestration/canvas-explain', body: {
      'doubt': doubt,
      'imageBase64': file.path, // Assuming file.path contains base64 or URI to send
      'language': 'en',
      'difficultyLevel': 3,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final explanation = data['explanation'] ?? "I've analyzed the attachment.";
      return ChatMessage(
        id: 'ai_exp_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'AI',
        text: explanation,
        options: [],
        attachments: [],
      );
    } else {
      throw Exception('Failed to send explain request: ${response.statusCode}');
    }
  }
}

final httpInterviewRepositoryProvider = Provider((ref) => HttpInterviewRepository());
