package com.oreo.engine.orchestration.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "flashcards")
@Data
@NoArgsConstructor
public class Flashcard {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID userId;

    @Column(length = 1000)
    private String front;

    @Column(length = 2000)
    private String back;

    @Column(length = 255)
    private String album;

    @Column(length = 255)
    private String subAlbum;

    // SuperMemo-2 Spaced Repetition Fields
    private LocalDate nextReviewDate;
    private int intervalDays;
    private float easeFactor = 2.5f;
    private int consecutiveCorrectAnswers = 0;
}
