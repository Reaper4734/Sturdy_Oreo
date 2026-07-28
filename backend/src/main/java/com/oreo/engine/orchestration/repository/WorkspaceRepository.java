package com.oreo.engine.orchestration.repository;

import com.oreo.engine.orchestration.model.Workspace;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface WorkspaceRepository extends JpaRepository<Workspace, String> {
    List<Workspace> findByUserId(UUID userId);
}
