import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';

class HttpIngestionRepository {
  final ApiClient _apiClient = ApiClient();

  Future<void> ingestVideo(String videoId) async {
    final response = await _apiClient.post('/orchestration/ingest', body: {
      'videoId': videoId,
    });

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception('Failed to ingest video: ${response.statusCode}');
    }
  }


}

final httpIngestionRepositoryProvider = Provider((ref) => HttpIngestionRepository());
