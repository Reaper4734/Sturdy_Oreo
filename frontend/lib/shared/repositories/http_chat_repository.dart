import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';

class HttpChatRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getUserChats() async {
    final response = await _apiClient.get('/orchestration/chats');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  Future<Map<String, dynamic>> createChat(String initialMessage) async {
    final response = await _apiClient.post('/orchestration/chats', body: {
      'message': initialMessage,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create chat');
  }

  Future<List<dynamic>> getChatMessages(String threadId) async {
    final response = await _apiClient.get('/orchestration/chats/$threadId/messages');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }
}

final httpChatRepositoryProvider = Provider((ref) => HttpChatRepository());
