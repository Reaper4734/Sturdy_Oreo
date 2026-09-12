import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import '../models/mind_map_model.dart';

class HttpMindMapRepository {
  final ApiClient _apiClient = ApiClient();

  Future<SubjectCluster> getSubjectCluster(String subject) async {
    final response = await _apiClient.post('/v1/mindmap/generate', body: {
      'subjectTitle': subject,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SubjectCluster.fromJson(data);
    } else {
      throw Exception('Failed to generate mind map: ${response.statusCode}');
    }
  }
}

final httpMindMapRepositoryProvider = Provider((ref) => HttpMindMapRepository());
