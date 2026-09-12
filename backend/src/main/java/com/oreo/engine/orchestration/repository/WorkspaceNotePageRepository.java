package com.oreo.engine.orchestration.repository;

import com.oreo.engine.orchestration.model.WorkspaceNotePage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WorkspaceNotePageRepository extends JpaRepository<WorkspaceNotePage, String> {
    List<WorkspaceNotePage> findByWorkspaceIdOrderBySortOrderAscCreatedAtAsc(String workspaceId);
    Optional<WorkspaceNotePage> findByIdAndWorkspaceId(String id, String workspaceId);
    List<WorkspaceNotePage> findByParentPageId(String parentPageId);
    void deleteByWorkspaceId(String workspaceId);
}
