import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/flashcard_model.dart';

class HttpFlashcardRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<FlashcardItem>> generateFlashcards(String topic) async {
    final response = await _apiClient.post('/orchestration/assessments/flashcards', body: {
      'topic': topic,
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((f) => FlashcardItem(
          id: f['id'] ?? 'fc_${DateTime.now().millisecondsSinceEpoch}',
          front: f['frontText'] ?? f['question'] ?? 'Question?',
          back: f['backText'] ?? f['answer'] ?? 'Answer.',
          topicTag: topic,
        )).toList();
    } else {
      throw Exception('Failed to generate flashcards: ${response.statusCode}');
    }
  }
}

final httpFlashcardRepositoryProvider = Provider((ref) => HttpFlashcardRepository());
