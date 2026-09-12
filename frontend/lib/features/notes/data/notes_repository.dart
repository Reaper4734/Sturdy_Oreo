import '../models/note_page_model.dart';
import '../models/note_block_model.dart';

abstract class NotesRepository {
  Future<List<NotePage>> fetchPages(String workspaceId);
  Future<NotePage> createPage(String workspaceId, {String? title, String? parentPageId, String? icon, List<NoteBlock>? blocks});
  Future<NotePage> fetchPage(String workspaceId, String pageId);
  Future<NotePage> updatePage(String workspaceId, String pageId, {String? title, String? parentPageId, String? icon, int? sortOrder});
  Future<void> deletePage(String workspaceId, String pageId);
  Future<NotePage> saveBlocks(String workspaceId, String pageId, List<NoteBlock> blocks);
}
