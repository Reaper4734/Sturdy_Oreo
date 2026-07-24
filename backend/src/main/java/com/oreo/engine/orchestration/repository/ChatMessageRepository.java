package com.oreo.engine.orchestration.repository;

import com.oreo.engine.orchestration.model.ChatMessageEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessageEntity, UUID> {
    List<ChatMessageEntity> findByThreadIdOrderByCreatedAtAsc(UUID threadId);
}
