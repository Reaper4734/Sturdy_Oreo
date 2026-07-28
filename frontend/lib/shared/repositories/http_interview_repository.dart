import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import '../models/micro_interview_model.dart';
import '../services/file_picker_service.dart';

class HttpInterviewRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ChatMessage> sendUserResponse(String text, String history, {List<AttachedFileModel>? files}) async {
    final response = await _apiClient.post('/orchestration/interview', body: {
      'message': text,
      'history': history,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final replyToUser = data['replyToUser'] ?? "I didn't understand that.";
      final optionsRaw = data['options'] as List<dynamic>?;
      final internalState = data['internalState'] as Map<String, dynamic>?;
      
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
}

final httpInterviewRepositoryProvider = Provider((ref) => HttpInterviewRepository());
