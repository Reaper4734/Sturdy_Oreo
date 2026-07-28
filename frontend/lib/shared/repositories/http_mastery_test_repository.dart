import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/shared/models/mastery_test_model.dart';
class HttpMasteryTestRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<QuestionItem>> generateAssessment(String topic) async {
    try {
      final response = await _apiClient.post('/orchestration/assessments/generate', body: {
        'topic': topic,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final questionsRaw = data['questions'] as List<dynamic>? ?? [];
        
        if (questionsRaw.isNotEmpty) {
          return questionsRaw.map((q) {
            final typeStr = q['type'] as String? ?? 'mcq';
            final optionsRaw = q['options'] as List<dynamic>? ?? [];
            return QuestionItem(
              id: q['id'] ?? 'q_\${DateTime.now().millisecondsSinceEpoch}',
              topicTag: q['topicTag'] ?? topic,
              questionText: q['questionText'] ?? '',
              type: typeStr == 'subjective' ? QuestionType.subjective : QuestionType.longMcq,
              options: optionsRaw.map((o) => QuestionnaireOption(
                id: o['id'] ?? 'o_\${DateTime.now().millisecondsSinceEpoch}',
                text: o['text'] ?? '',
                isCorrect: o['isCorrect'] == true,
                explanation: o['explanation'],
              )).toList(),
            );
          }).toList();
        }
      }
    } catch (e) {
      // throw Exception('HttpMasteryTestRepository error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> evaluateAnswer(String topic, String question, String answer) async {
    try {
      final response = await _apiClient.post('/orchestration/assessments/evaluate', body: {
        'topic': topic,
        'question': question,
        'answer': answer,
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // return mock error
    }
    return {
      'isPassed': false,
      'score': 0,
      'feedback': 'Failed to evaluate answer.',
      'suggestedReviewTopic': topic
    };
  }

  // Keep these synchronous since they don't have backend equivalents yet
  List<QuestionItem> getShortPopupQuestions() => [];
  QuestionItem getCodeTerminalQuestion() => QuestionItem(id: 'code1', topicTag: 'Code', questionText: 'Write code', type: QuestionType.subjective);
}

final httpMasteryTestRepositoryProvider = Provider((ref) => HttpMasteryTestRepository());
