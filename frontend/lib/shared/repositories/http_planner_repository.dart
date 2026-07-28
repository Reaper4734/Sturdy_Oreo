import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';

class HttpPlannerRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> generatePlan(String learningGoal, int totalHoursAvailable) async {
    final response = await _apiClient.post('/orchestration/planner/generate', body: {
      'learningGoal': learningGoal,
      'totalHoursAvailable': totalHoursAvailable.toString(),
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to generate plan');
  }

  Future<void> completeTask(String taskId) async {
    final response = await _apiClient.put('/orchestration/planner/task/$taskId/complete', body: {});
    if (response.statusCode != 200) {
      throw Exception('Failed to complete task');
    }
  }
}

final httpPlannerRepositoryProvider = Provider((ref) => HttpPlannerRepository());
