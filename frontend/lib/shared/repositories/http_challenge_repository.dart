import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';

class HttpChallengeRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> generateChallenge({
    required String language,
    String topic = '',
    String videoId = '',
    int videoTimestamp = 0,
    String doubtContext = '',
  }) async {
    final response = await _apiClient.post('/orchestration/challenge/generate', body: {
      'language': language,
      'topic': topic,
      'videoId': videoId,
      'videoTimestamp': videoTimestamp,
      'doubtContext': doubtContext.isNotEmpty ? doubtContext : topic,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to generate challenge: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> gradeChallenge({
    required String problemStatement,
    required String code,
    required String language,
  }) async {
    final response = await _apiClient.post('/orchestration/challenge/grade', body: {
      'problemStatement': problemStatement,
      'code': code,
      'language': language,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to grade challenge: ${response.statusCode}');
  }
}

final httpChallengeRepositoryProvider = Provider((ref) => HttpChallengeRepository());
