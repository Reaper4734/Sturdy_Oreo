package com.oreo.engine.orchestration.repository;

import com.oreo.engine.orchestration.model.ChatThread;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChatThreadRepository extends JpaRepository<ChatThread, UUID> {
    List<ChatThread> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
