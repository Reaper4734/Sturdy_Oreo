package com.oreo.engine.orchestration.repository;

import com.oreo.engine.orchestration.model.WorkspaceNoteBlock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WorkspaceNoteBlockRepository extends JpaRepository<WorkspaceNoteBlock, String> {
    List<WorkspaceNoteBlock> findByPageIdOrderBySortOrderAscCreatedAtAsc(String pageId);
    void deleteByPageId(String pageId);
}
