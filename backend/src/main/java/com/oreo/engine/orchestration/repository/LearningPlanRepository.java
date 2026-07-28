package com.oreo.engine.orchestration.repository;

import com.oreo.engine.orchestration.model.LearningPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface LearningPlanRepository extends JpaRepository<LearningPlan, UUID> {
    Optional<LearningPlan> findByChatThreadId(UUID chatThreadId);
    Optional<LearningPlan> findByUserId(UUID userId);
}
