package com.oreo.engine.orchestration.repository;

import com.oreo.engine.orchestration.model.Flashcard;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface FlashcardRepository extends JpaRepository<Flashcard, UUID> {
    List<Flashcard> findByUserId(UUID userId);
    List<Flashcard> findByUserIdAndNextReviewDateLessThanEqual(UUID userId, LocalDate date);
}
