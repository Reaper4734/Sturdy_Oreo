package com.oreo.engine.orchestration.repository;

import com.oreo.engine.orchestration.model.CurriculumCache;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CurriculumCacheRepository extends JpaRepository<CurriculumCache, UUID> {
    Optional<CurriculumCache> findBySubject(String subject);
}
