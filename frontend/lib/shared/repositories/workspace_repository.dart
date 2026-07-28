import '../models/workspace_model.dart';

/// Abstract contract for Workspace Lifecycle persistence and management.
/// /ponytail ceiling: swap MockWorkspaceRepository for SqliteWorkspaceRepository
/// or ApiWorkspaceRepository without modifying any UI or provider code.
abstract class IWorkspaceRepository {
  Future<List<WorkspaceModel>> getAll();
  Future<WorkspaceModel?> getById(String id);
  Future<WorkspaceModel> create(WorkspaceModel ws);
  Future<void> update(WorkspaceModel ws);
  Future<void> delete(String id);
  Future<WorkspaceModel> duplicate(String id);
  Future<void> archive(String id, {required bool isArchived});
  Future<void> pin(String id, {required bool isPinned});
}
