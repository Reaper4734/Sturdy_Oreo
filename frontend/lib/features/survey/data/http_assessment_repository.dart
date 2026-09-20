import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/mastery_test_model.dart';

class HttpAssessmentRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<QuestionItem>> generateAssessment(String topic) async {
    final response = await _apiClient.post('/orchestration/assessments/generate', body: {
      'topic': topic,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final questions = data['questions'] as List? ?? [];

      return questions.map((q) {
        final qType = q['type'] == 'mcq' ? QuestionType.longMcq : QuestionType.shortPopup;
        final options = (q['options'] as List? ?? []).map((o) => QuestionnaireOption(
          id: o['id'] ?? 'opt_temp',
          text: o['text'] ?? '',
          isCorrect: o['isCorrect'] ?? false,
          explanation: o['explanation'],
        )).toList();

        return QuestionItem(
          id: q['id'] ?? 'q_temp',
          topicTag: q['topicTag'] ?? topic,
          questionText: q['questionText'] ?? '',
          type: qType,
          options: options,
        );
      }).toList();
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>> evaluateAnswer(String topic, String question, String answer) async {
    final response = await _apiClient.post('/orchestration/assessments/evaluate', body: {
      'topic': topic,
      'question': question,
      'answer': answer,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to evaluate answer: ${response.statusCode}');
    }
  }
}

final httpAssessmentRepositoryProvider = Provider((ref) => HttpAssessmentRepository());
