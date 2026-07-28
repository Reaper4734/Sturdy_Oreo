import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';

class HttpChallengeRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> generateChallenge(String topic, String difficulty) async {
    try {
      final response = await _apiClient.post('/orchestration/challenge/generate', body: {
        'topic': topic,
        'difficulty': difficulty,
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Handle error
    }
    throw Exception('Failed to generate challenge');
  }

  Future<Map<String, dynamic>> gradeChallenge(String challengeId, String code) async {
    try {
      final response = await _apiClient.post('/orchestration/challenge/grade', body: {
        'challengeId': challengeId,
        'code': code,
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Handle error
    }
    throw Exception('Failed to grade challenge');
  }
}

final httpChallengeRepositoryProvider = Provider((ref) => HttpChallengeRepository());
