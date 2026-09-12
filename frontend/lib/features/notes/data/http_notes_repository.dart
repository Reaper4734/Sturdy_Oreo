import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../models/note_page_model.dart';
import '../models/note_block_model.dart';

final notesRepositoryProvider = Provider<HttpNotesRepository>((ref) {
  return HttpNotesRepository();
});

class HttpNotesRepository {
  final ApiClient _apiClient = ApiClient();


  Future<List<NotePage>> fetchPages(String workspaceId) async {
    final response = await _apiClient.get('/v1/workspaces/$workspaceId/notes/pages');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => NotePage.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch note pages: ${response.statusCode}');
  }

  Future<NotePage> createPage(
    String workspaceId, {
    String? title,
    String? parentPageId,
    String? icon,
    List<NoteBlock>? blocks,
  }) async {
    final payload = <String, dynamic>{
      'title': title ?? 'Untitled',
      if (parentPageId != null) 'parentPageId': parentPageId,
      if (icon != null) 'icon': icon,
      if (blocks != null) 'blocks': blocks.map((b) => b.toJson()).toList(),
    };

    final response = await _apiClient.post(
      '/v1/workspaces/$workspaceId/notes/pages',
      body: payload,
    );

    if (response.statusCode == 200) {
      return NotePage.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create note page: ${response.statusCode}');
  }

  Future<NotePage> fetchPage(String workspaceId, String pageId) async {
    final response = await _apiClient.get('/v1/workspaces/$workspaceId/notes/pages/$pageId');
    if (response.statusCode == 200) {
      return NotePage.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch note page: ${response.statusCode}');
  }

  Future<NotePage> updatePage(
    String workspaceId,
    String pageId, {
    String? title,
    String? parentPageId,
    String? icon,
    int? sortOrder,
  }) async {
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (parentPageId != null) 'parentPageId': parentPageId,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };

    final response = await _apiClient.put(
      '/v1/workspaces/$workspaceId/notes/pages/$pageId',
      body: payload,
    );

    if (response.statusCode == 200) {
      return NotePage.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update note page: ${response.statusCode}');
  }

  Future<void> deletePage(String workspaceId, String pageId) async {
    final response = await _apiClient.delete('/v1/workspaces/$workspaceId/notes/pages/$pageId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete note page: ${response.statusCode}');
    }
  }

  Future<NotePage> saveBlocks(String workspaceId, String pageId, List<NoteBlock> blocks) async {
    final payload = {
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };

    final response = await _apiClient.put(
      '/v1/workspaces/$workspaceId/notes/pages/$pageId/blocks',
      body: payload,
    );

    if (response.statusCode == 200) {
      return NotePage.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to save blocks: ${response.statusCode}');
  }
}
