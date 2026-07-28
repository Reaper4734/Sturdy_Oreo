import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workspace_model.dart';
import '../repositories/mock_workspace_repository.dart';
import '../repositories/workspace_repository.dart';

/// Provides the workspace repository instance
final workspaceRepositoryProvider = Provider<IWorkspaceRepository>((ref) {
  return MockWorkspaceRepository();
});

/// Manages the list of Learning Spaces and handles CRUD lifecycle mutations.
class WorkspaceListNotifier extends StateNotifier<List<WorkspaceModel>> {
  final IWorkspaceRepository _repository;

  WorkspaceListNotifier(this._repository) : super([]) {
    loadWorkspaces();
  }

  Future<void> loadWorkspaces() async {
    final list = await _repository.getAll();
    state = list;
  }

  Future<WorkspaceModel> createWorkspace(WorkspaceModel ws) async {
    final created = await _repository.create(ws);
    await loadWorkspaces();
    return created;
  }

  Future<void> deleteWorkspace(String id) async {
    await _repository.delete(id);
    await loadWorkspaces();
  }

  Future<WorkspaceModel> duplicateWorkspace(String id) async {
    final dup = await _repository.duplicate(id);
    await loadWorkspaces();
    return dup;
  }

  Future<void> archiveWorkspace(String id, bool isArchived) async {
    await _repository.archive(id, isArchived: isArchived);
    await loadWorkspaces();
  }

  Future<void> pinWorkspace(String id, bool isPinned) async {
    await _repository.pin(id, isPinned: isPinned);
    await loadWorkspaces();
  }

  Future<void> renameWorkspace(String id, String newTitle) async {
    final ws = await _repository.getById(id);
    if (ws != null) {
      ws.title = newTitle;
      await _repository.update(ws);
      await loadWorkspaces();
    }
  }

  Future<void> touchWorkspace(String id) async {
    final ws = await _repository.getById(id);
    if (ws != null) {
      ws.lastOpened = DateTime.now();
      await _repository.update(ws);
      await loadWorkspaces();
    }
  }

  Future<void> updateActiveLearningContext(String id, String newContext) async {
    final ws = await _repository.getById(id);
    if (ws != null) {
      ws.activeLearningContext = newContext;
      await _repository.update(ws);
      await loadWorkspaces();
    }
  }

  Future<void> updateActiveTab(String id, String newTabId) async {
    final ws = await _repository.getById(id);
    if (ws != null) {
      ws.activeTabId = newTabId;
      await _repository.update(ws);
      await loadWorkspaces();
    }
  }

  Future<void> confirmCourse(String id) async {
    final ws = await _repository.getById(id);
    if (ws != null) {
      ws.isCourseConfirmed = true;
      await _repository.update(ws);
      await loadWorkspaces();
    }
  }

  Future<void> updateWorkspace(WorkspaceModel ws) async {
    await _repository.update(ws);
    await loadWorkspaces();
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
