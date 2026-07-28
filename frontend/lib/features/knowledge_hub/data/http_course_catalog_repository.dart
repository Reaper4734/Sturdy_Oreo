import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import 'course_catalog_model.dart';

class HttpCourseCatalogRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<CourseCatalogEntry>> getAllCourses() async {
    final res = await _apiClient.get('/catalog/all');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => _parseEntry(e)).toList();
    }
    throw Exception('Failed to fetch catalog');
  }

  Future<List<CourseCatalogEntry>> getRecommendations(String? domain) async {
    final res = await _apiClient.get('/catalog/recommendations${domain != null ? "?domain=$domain" : ""}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => _parseEntry(e)).toList();
    }
    throw Exception('Failed to fetch recommendations');
  }

  Future<List<CourseCatalogEntry>> search(String query) async {
    final res = await _apiClient.get('/catalog/search?query=$query');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => _parseEntry(e)).toList();
    }
    throw Exception('Failed to search catalog');
  }

  CourseCatalogEntry _parseEntry(dynamic e) {
    return CourseCatalogEntry(
      id: e['id'] ?? '',
      title: e['title'] ?? '',
      category: e['category'] ?? '',
      difficulty: e['difficulty'] ?? '',
      tags: List<String>.from(e['tags'] ?? []),
      estimatedHours: e['estimatedHours'] ?? 0,
      thumbnailUrl: e['thumbnailUrl'] ?? '',
    );
  }
}

final httpCourseCatalogRepositoryProvider = Provider((ref) => HttpCourseCatalogRepository());
