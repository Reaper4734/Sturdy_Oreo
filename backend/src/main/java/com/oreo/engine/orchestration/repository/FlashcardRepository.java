package com.oreo.engine.orchestration.repository;

import com.oreo.engine.orchestration.model.Flashcard;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface FlashcardRepository extends JpaRepository<Flashcard, UUID> {
    List<Flashcard> findByUserId(UUID userId);
    List<Flashcard> findByUserIdAndNextReviewDateLessThanEqual(UUID userId, LocalDate date);
    
    List<Flashcard> findTop5ByAlbumAndSubAlbum(String album, String subAlbum);
    
    @Query("SELECT DISTINCT f.album, f.subAlbum FROM Flashcard f WHERE f.userId = :userId AND f.album IS NOT NULL")
    List<Object[]> findDistinctAlbumsByUserId(@Param("userId") UUID userId);
}
