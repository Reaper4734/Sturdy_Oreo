import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workspace_model.dart';
import '../../features/workspace/data/http_workspace_repository.dart';

/// Provides the workspace repository instance
final workspaceRepositoryProvider = Provider<HttpWorkspaceRepository>((ref) {
  return HttpWorkspaceRepository();
});

class WorkspaceListNotifier extends StateNotifier<List<WorkspaceModel>> {
  final HttpWorkspaceRepository _repository;

  WorkspaceListNotifier(this._repository) : super([]) {
    loadWorkspaces();
  }

  Future<void> loadWorkspaces() async {
    try {
      final list = await _repository.getAll();
      state = list;
    } catch (e) {
      debugPrint("Failed to load workspaces: $e");
      state = [];
    }
  }

  Future<WorkspaceModel> createWorkspace(WorkspaceModel ws) async {
    final created = await _repository.create(ws);
    state = [...state, created];
    return created;
  }

  Future<void> deleteWorkspace(String id) async {
    await _repository.delete(id);
    state = state.where((w) => w.id != id).toList();
  }

  Future<WorkspaceModel> duplicateWorkspace(String id) async {
    final dup = await _repository.duplicate(id);
    state = [...state, dup];
    return dup;
  }

  /// Optimistic local update: mutate, re-emit new list with fresh reference, fire-and-forget PUT.
  /// Eliminates the GET→PUT→GET cascade and ensures Riverpod providers trigger re-renders.
  void _optimisticUpdate(String id, void Function(WorkspaceModel ws) mutate) {
    try {
      final index = state.indexWhere((w) => w.id == id);
      if (index != -1) {
        final ws = state[index];
        mutate(ws);
        final freshWs = ws.copyWith();
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index) freshWs else state[i]
        ];
        _repository.update(freshWs); // fire-and-forget
      }
    } catch (_) {
      debugPrint('Workspace not found in local state: $id');
    }
  }

  Future<void> archiveWorkspace(String id, bool isArchived) async {
    _optimisticUpdate(id, (ws) => ws.isArchived = isArchived);
  }

  Future<void> pinWorkspace(String id, bool isPinned) async {
    _optimisticUpdate(id, (ws) => ws.isPinned = isPinned);
  }

  Future<void> renameWorkspace(String id, String newTitle) async {
    _optimisticUpdate(id, (ws) => ws.title = newTitle);
  }

  Future<void> touchWorkspace(String id) async {
    _optimisticUpdate(id, (ws) => ws.lastOpened = DateTime.now());
  }

  Future<void> updateActiveLearningContext(String id, String newContext) async {
    _optimisticUpdate(id, (ws) => ws.activeLearningContext = newContext);
  }

  Future<void> updateActiveTab(String id, String newTabId) async {
    _optimisticUpdate(id, (ws) => ws.activeTabId = newTabId);
  }

  Future<void> confirmCourse(String id) async {
    _optimisticUpdate(id, (ws) => ws.isCourseConfirmed = true);
  }

  Future<void> updateWorkspace(WorkspaceModel ws) async {
    state = [...state];
    _repository.update(ws); // fire-and-forget
  }
}

/// Root StateNotifierProvider for the workspace list
final workspaceListProvider = StateNotifierProvider<WorkspaceListNotifier, List<WorkspaceModel>>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return WorkspaceListNotifier(repo);
});

/// Active workspace ID (null if no workspace loaded)
final activeWorkspaceIdProvider = StateProvider<String?>((ref) => null);

/// Derived active workspace model
final activeWorkspaceProvider = Provider<WorkspaceModel?>((ref) {
  final id = ref.watch(activeWorkspaceIdProvider);
  final list = ref.watch(workspaceListProvider);
  if (list.isEmpty) return null;

  if (id == null) return list.first;

  try {
    return list.firstWhere((w) => w.id == id);
  } catch (_) {
    return list.first;
  }
});

/// Controls visibility of the left slide-out Learning Spaces Explorer panel
final workspacePanelOpenProvider = StateProvider<bool>((ref) => false);

/// Search query inside the Learning Spaces explorer
final workspaceSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered workspaces for the Explorer panel
final filteredWorkspaceListProvider = Provider<List<WorkspaceModel>>((ref) {
  final list = ref.watch(workspaceListProvider);
  final query = ref.watch(workspaceSearchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return list;
  return list.where((w) {
    return w.title.toLowerCase().contains(query) ||
        w.subject.toLowerCase().contains(query) ||
        w.activeLearningContext.toLowerCase().contains(query) ||
        w.difficulty.toLowerCase().contains(query);
  }).toList();
});

/// Notion-style auto-save status indicator
final autoSaveStatusProvider = StateProvider<String>((ref) => 'Saved');

/// Helper to trigger feedback in UI during any mutation
void triggerAutoSaveFeedback(WidgetRef ref) {
  ref.read(autoSaveStatusProvider.notifier).state = 'Saving...';
  Timer(const Duration(milliseconds: 600), () {
    ref.read(autoSaveStatusProvider.notifier).state = 'Saved';
  });
}

/// Global provider to prefill or attach text to the chat input
final chatPrefillInputProvider = StateProvider<String?>((ref) => null);

/// Global provider to switch LearningLabSidebar tab (0 = Oreo AI, 1 = Roadmap)
final sidebarSelectedTabProvider = StateProvider<int>((ref) => 0);
