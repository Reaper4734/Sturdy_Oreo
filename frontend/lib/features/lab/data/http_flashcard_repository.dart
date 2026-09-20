import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/flashcard_model.dart';

class HttpFlashcardRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<FlashcardItem>> generateFlashcards(String topic) async {
    final response = await _apiClient.post('/orchestration/generate-flashcards', body: {
      'topic': topic,
    });

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // Backend returns [{frontQuestion, backAnswer}, ...] directly
      final List<dynamic> flashcardsList = decoded is List ? decoded : (decoded['cards'] ?? decoded['flashcards'] ?? []);
      return flashcardsList.asMap().entries.map((entry) => FlashcardItem(
          id: 'fc_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
          front: entry.value['frontQuestion'] ?? entry.value['front'] ?? entry.value['question'] ?? 'Question?',
          back: entry.value['backAnswer'] ?? entry.value['back'] ?? entry.value['answer'] ?? 'Answer.',
          topicTag: topic,
        )).toList();
    } else {
      throw Exception('Failed to generate flashcards: ${response.statusCode}');
    }
  }

  Future<void> reviewFlashcard(String cardId, int quality) async {
    try {
      await _apiClient.post('/orchestration/assessments/flashcards/$cardId/review', body: {
        'quality': quality,
      });
    } catch (e) {
      // Ephemeral cards reviewed in memory gracefully
    }
  }
}

final httpFlashcardRepositoryProvider = Provider((ref) => HttpFlashcardRepository());
