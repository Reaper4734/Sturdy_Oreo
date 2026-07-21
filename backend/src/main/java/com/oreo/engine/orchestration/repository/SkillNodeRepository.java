package com.oreo.engine.orchestration.repository;

import com.oreo.engine.orchestration.model.SkillNode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SkillNodeRepository extends JpaRepository<SkillNode, UUID> {
    List<SkillNode> findByUserId(UUID userId);
}
