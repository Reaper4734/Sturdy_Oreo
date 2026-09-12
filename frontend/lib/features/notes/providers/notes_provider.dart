import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/workspace_providers.dart';
import '../data/http_notes_repository.dart';
import '../data/notes_repository.dart';
import '../models/block_type.dart';
import '../models/note_block_model.dart';
import '../models/note_page_model.dart';

/// State of Notes for the active workspace
class NotesState {
  final String? workspaceId;
  final List<NotePage> pages;
  final String? selectedPageId;
  final NotePage? activePage;
  final bool isLoading;
  final bool isSaving;
  final String searchQuery;
  final Set<String> collapsedParentIds;
  final String? errorMessage;

  const NotesState({
    this.workspaceId,
    this.pages = const [],
    this.selectedPageId,
    this.activePage,
    this.isLoading = false,
    this.isSaving = false,
    this.searchQuery = '',
    this.collapsedParentIds = const {},
    this.errorMessage,
  });

  NotesState copyWith({
    String? workspaceId,
    List<NotePage>? pages,
    String? selectedPageId,
    bool clearSelectedPage = false,
    NotePage? activePage,
    bool clearActivePage = false,
    bool? isLoading,
    bool? isSaving,
    String? searchQuery,
    Set<String>? collapsedParentIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotesState(
      workspaceId: workspaceId ?? this.workspaceId,
      pages: pages ?? this.pages,
      selectedPageId: clearSelectedPage ? null : (selectedPageId ?? this.selectedPageId),
      activePage: clearActivePage ? null : (activePage ?? this.activePage),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      searchQuery: searchQuery ?? this.searchQuery,
      collapsedParentIds: collapsedParentIds ?? this.collapsedParentIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final notesNotifierProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  final activeWorkspaceId = ref.watch(activeWorkspaceIdProvider);
  return NotesNotifier(repo, activeWorkspaceId);
});

class NotesNotifier extends StateNotifier<NotesState> {
  final NotesRepository _repository;
  Timer? _debounceSaveTimer;

  NotesNotifier(this._repository, String? activeWorkspaceId)
      : super(NotesState(workspaceId: activeWorkspaceId)) {
    if (activeWorkspaceId != null && activeWorkspaceId.isNotEmpty) {
      loadWorkspaceNotes(activeWorkspaceId);
    }
  }

  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    super.dispose();
  }

  /// Called whenever active workspace switches or initializes
  Future<void> loadWorkspaceNotes(String workspaceId) async {
    // 1. Immediately clear old workspace state to ensure strict isolation
    _debounceSaveTimer?.cancel();
    state = NotesState(
      workspaceId: workspaceId,
      isLoading: true,
    );

    try {
      final pages = await _repository.fetchPages(workspaceId);
      if (pages.isEmpty) {
        // Auto-create initial default note page for this workspace
        final newPage = await _repository.createPage(
          workspaceId,
          title: 'Welcome to Notes',
          icon: null,
          blocks: [
            NoteBlock(
              id: 'b_welcome_1',
              pageId: '',
              type: BlockType.heading1,
              content: 'Getting Started with Notes',
              sortOrder: 0,
            ),
            NoteBlock(
              id: 'b_welcome_2',
              pageId: '',
              type: BlockType.callout,
              content: 'Type "/" anywhere to insert headings, checklists, code blocks, or callouts.',
              sortOrder: 1,
              metadata: {'calloutType': 'tip'},
            ),
            NoteBlock(
              id: 'b_welcome_3',
              pageId: '',
              type: BlockType.checklist,
              content: 'Explore nested note pages in the sidebar',
              sortOrder: 2,
              metadata: {'checked': false},
            ),
            NoteBlock(
              id: 'b_welcome_4',
              pageId: '',
              type: BlockType.paragraph,
              content: 'Start writing your concepts, code snippets, and study notes here...',
              sortOrder: 3,
            ),
          ],
        );
        state = state.copyWith(
          pages: [newPage],
          selectedPageId: newPage.id,
          activePage: newPage,
          isLoading: false,
        );
      } else {
        final firstPageId = pages.first.id;
        state = state.copyWith(
          pages: pages,
          selectedPageId: firstPageId,
          isLoading: false,
        );
        await selectPage(firstPageId);
      }
    } catch (e) {
      debugPrint('Error loading workspace notes: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notes for this workspace.',
      );
    }
  }

  /// Select a page and load its blocks
  Future<void> selectPage(String pageId) async {
    final wsId = state.workspaceId;
    if (wsId == null) return;

    // Flush any pending auto-save before switching page
    _flushPendingSave();

    state = state.copyWith(selectedPageId: pageId, isLoading: state.activePage == null);

    try {
      final page = await _repository.fetchPage(wsId, pageId);
      state = state.copyWith(
        activePage: page,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error selecting page: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load note page.',
      );
    }
  }

  /// Create a new note page
  Future<NotePage?> createPage({String? title, String? parentPageId, String? icon}) async {
    final wsId = state.workspaceId;
    if (wsId == null) return null;

    try {
      final newPage = await _repository.createPage(
        wsId,
        title: title ?? 'Untitled',
        parentPageId: parentPageId,
        icon: icon,
        blocks: [
          NoteBlock(
            id: 'b_${DateTime.now().millisecondsSinceEpoch}',
            pageId: '',
            type: BlockType.paragraph,
            content: '',
            sortOrder: 0,
          ),
        ],
      );

      final updatedPages = [...state.pages, newPage];
      state = state.copyWith(
        pages: updatedPages,
        selectedPageId: newPage.id,
        activePage: newPage,
      );
      return newPage;
    } catch (e) {
      debugPrint('Error creating page: $e');
      state = state.copyWith(errorMessage: 'Failed to create page.');
      return null;
    }
  }

  /// Rename a note page
  void updatePageTitle(String newTitle) {
    final page = state.activePage;
    final wsId = state.workspaceId;
    if (page == null || wsId == null) return;

    final updatedPage = page.copyWith(title: newTitle, updatedAt: DateTime.now());
    final updatedPages = state.pages.map((p) => p.id == page.id ? p.copyWith(title: newTitle) : p).toList();

    state = state.copyWith(
      activePage: updatedPage,
      pages: updatedPages,
    );

    _debounce(() {
      _repository.updatePage(wsId, page.id, title: newTitle);
    });
  }

  /// Update page icon
  void updatePageIcon(String icon) {
    final page = state.activePage;
    final wsId = state.workspaceId;
    if (page == null || wsId == null) return;

    final updatedPage = page.copyWith(icon: icon, updatedAt: DateTime.now());
    final updatedPages = state.pages.map((p) => p.id == page.id ? p.copyWith(icon: icon) : p).toList();

    state = state.copyWith(
      activePage: updatedPage,
      pages: updatedPages,
    );

    _repository.updatePage(wsId, page.id, icon: icon);
  }

  /// Delete a note page
  Future<void> deletePage(String pageId) async {
    final wsId = state.workspaceId;
    if (wsId == null) return;

    try {
      await _repository.deletePage(wsId, pageId);
      final remaining = state.pages.where((p) => p.id != pageId && p.parentPageId != pageId).toList();

      String? nextSelectedId;

      if (remaining.isNotEmpty) {
        nextSelectedId = remaining.first.id;
      }

      state = state.copyWith(
        pages: remaining,
        selectedPageId: nextSelectedId,
        clearSelectedPage: nextSelectedId == null,
        clearActivePage: nextSelectedId == null,
      );

      if (nextSelectedId != null) {
        await selectPage(nextSelectedId);
      }
    } catch (e) {
      debugPrint('Error deleting page: $e');
      state = state.copyWith(errorMessage: 'Failed to delete page.');
    }
  }

  /// Toggle collapse/expand for a parent page in sidebar
  void toggleParentCollapse(String parentId) {
    final current = Set<String>.from(state.collapsedParentIds);
    if (current.contains(parentId)) {
      current.remove(parentId);
    } else {
      current.add(parentId);
    }
    state = state.copyWith(collapsedParentIds: current);
  }

  /// Set search query within notes
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // --- Block Editing Operations ---

  /// Add a new block at index or end
  void addBlock({required BlockType type, int? atIndex, String initialContent = '', Map<String, dynamic>? metadata}) {
    final page = state.activePage;
    if (page == null) return;

    final newBlock = NoteBlock(
      id: 'block_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}',
      pageId: page.id,
      type: type,
      content: initialContent,
      sortOrder: atIndex ?? page.blocks.length,
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final List<NoteBlock> updatedBlocks = List.from(page.blocks);
    if (atIndex != null && atIndex >= 0 && atIndex <= updatedBlocks.length) {
      updatedBlocks.insert(atIndex, newBlock);
    } else {
      updatedBlocks.add(newBlock);
    }

    _updateActivePageBlocks(updatedBlocks);
  }

  /// Update block content
  void updateBlockContent(String blockId, String content) {
    final page = state.activePage;
    if (page == null) return;

    final updatedBlocks = page.blocks.map((b) {
      if (b.id == blockId) {
        return b.copyWith(content: content, updatedAt: DateTime.now());
      }
      return b;
    }).toList();

    _updateActivePageBlocks(updatedBlocks);
  }

  /// Change block type (Turn Into...)
  void turnBlockInto(String blockId, BlockType newType) {
    final page = state.activePage;
    if (page == null) return;

    final updatedBlocks = page.blocks.map((b) {
      if (b.id == blockId) {
        final Map<String, dynamic> newMeta = Map.from(b.metadata);
        if (newType == BlockType.callout && !newMeta.containsKey('calloutType')) {
          newMeta['calloutType'] = 'info';
        } else if (newType == BlockType.code && !newMeta.containsKey('language')) {
          newMeta['language'] = 'java';
        } else if (newType == BlockType.checklist && !newMeta.containsKey('checked')) {
          newMeta['checked'] = false;
        }
        return b.copyWith(type: newType, metadata: newMeta, updatedAt: DateTime.now());
      }
      return b;
    }).toList();

    _updateActivePageBlocks(updatedBlocks);
  }

  /// Update block metadata (e.g. checklist checked toggle, code language, callout type)
  void updateBlockMetadata(String blockId, Map<String, dynamic> metadata) {
    final page = state.activePage;
    if (page == null) return;

    final updatedBlocks = page.blocks.map((b) {
      if (b.id == blockId) {
        final mergedMeta = Map<String, dynamic>.from(b.metadata)..addAll(metadata);
        return b.copyWith(metadata: mergedMeta, updatedAt: DateTime.now());
      }
      return b;
    }).toList();

    _updateActivePageBlocks(updatedBlocks);
  }

  /// Duplicate a block
  void duplicateBlock(String blockId) {
    final page = state.activePage;
    if (page == null) return;

    final index = page.blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final original = page.blocks[index];
    final copy = original.copyWith(
      id: 'block_${DateTime.now().millisecondsSinceEpoch}_copy',
      sortOrder: index + 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updatedBlocks = List<NoteBlock>.from(page.blocks)..insert(index + 1, copy);
    _updateActivePageBlocks(updatedBlocks);
  }

  /// Delete a block
  void deleteBlock(String blockId) {
    final page = state.activePage;
    if (page == null) return;

    List<NoteBlock> updatedBlocks = page.blocks.where((b) => b.id != blockId).toList();

    // Ensure at least 1 paragraph block remains
    if (updatedBlocks.isEmpty) {
      updatedBlocks = [
        NoteBlock(
          id: 'block_${DateTime.now().millisecondsSinceEpoch}',
          pageId: page.id,
          type: BlockType.paragraph,
          content: '',
          sortOrder: 0,
        ),
      ];
    }

    _updateActivePageBlocks(updatedBlocks);
  }

  /// Move block up
  void moveBlockUp(String blockId) {
    final page = state.activePage;
    if (page == null) return;

    final index = page.blocks.indexWhere((b) => b.id == blockId);
    if (index <= 0) return;

    final updatedBlocks = List<NoteBlock>.from(page.blocks);
    final block = updatedBlocks.removeAt(index);
    updatedBlocks.insert(index - 1, block);

    _updateActivePageBlocks(updatedBlocks);
  }

  /// Move block down
  void moveBlockDown(String blockId) {
    final page = state.activePage;
    if (page == null) return;

    final index = page.blocks.indexWhere((b) => b.id == blockId);
    if (index < 0 || index >= page.blocks.length - 1) return;

    final updatedBlocks = List<NoteBlock>.from(page.blocks);
    final block = updatedBlocks.removeAt(index);
    updatedBlocks.insert(index + 1, block);

    _updateActivePageBlocks(updatedBlocks);
  }

  /// Reorder blocks (e.g. from drag & drop)
  void reorderBlocks(int oldIndex, int newIndex) {
    final page = state.activePage;
    if (page == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final updatedBlocks = List<NoteBlock>.from(page.blocks);
    final item = updatedBlocks.removeAt(oldIndex);
    updatedBlocks.insert(newIndex, item);

    _updateActivePageBlocks(updatedBlocks);
  }

  void _updateActivePageBlocks(List<NoteBlock> blocks) {
    final page = state.activePage;
    final wsId = state.workspaceId;
    if (page == null || wsId == null) return;

    // Re-assign sortOrder
    final reindexed = List<NoteBlock>.generate(blocks.length, (i) {
      return blocks[i].copyWith(sortOrder: i);
    });

    final updatedPage = page.copyWith(
      blocks: reindexed,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(activePage: updatedPage);

    _debounce(() {
      _saveBlocksToServer(wsId, updatedPage.id, reindexed);
    });
  }

  void _debounce(VoidCallback action) {
    _debounceSaveTimer?.cancel();
    state = state.copyWith(isSaving: true);
    _debounceSaveTimer = Timer(const Duration(milliseconds: 600), () {
      action();
    });
  }

  Future<void> _saveBlocksToServer(String workspaceId, String pageId, List<NoteBlock> blocks) async {
    try {
      await _repository.saveBlocks(workspaceId, pageId, blocks);
      if (mounted) {
        state = state.copyWith(isSaving: false);
      }
    } catch (e) {
      debugPrint('Error saving blocks: $e');
      if (mounted) {
        state = state.copyWith(isSaving: false);
      }
    }
  }

  void _flushPendingSave() {
    if (_debounceSaveTimer != null && _debounceSaveTimer!.isActive) {
      _debounceSaveTimer!.cancel();
      final page = state.activePage;
      final wsId = state.workspaceId;
      if (page != null && wsId != null) {
        _saveBlocksToServer(wsId, page.id, page.blocks);
      }
    }
  }
}
