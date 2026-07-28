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

  // Not implemented in backend yet, but ready for RAG document upload
  Future<void> uploadDocument(String filePath) async {
    // Requires multipart upload support in ApiClient
    throw UnimplementedError('Multipart upload not yet supported in ApiClient');
  }
}

final httpIngestionRepositoryProvider = Provider((ref) => HttpIngestionRepository());
