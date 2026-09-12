package com.oreo.engine.orchestration;

import com.oreo.engine.orchestration.model.Flashcard;
import com.oreo.engine.orchestration.repository.FlashcardRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SpacedRepetitionTest {

    @Mock
    private FlashcardRepository flashcardRepository;

    private SpacedRepetitionService spacedRepetitionService;

    @BeforeEach
    void setUp() {
        spacedRepetitionService = new SpacedRepetitionService(flashcardRepository);
    }

    @Test
    void reviewCard_ShouldResetIntervalAndConsecutive_WhenQualityIsBelow3() {
        UUID cardId = UUID.randomUUID();
        Flashcard card = new Flashcard();
        card.setId(cardId);
        card.setConsecutiveCorrectAnswers(4);
        card.setIntervalDays(15);
        card.setEaseFactor(2.5f);

        when(flashcardRepository.findById(cardId)).thenReturn(Optional.of(card));
        when(flashcardRepository.save(any(Flashcard.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Flashcard updated = spacedRepetitionService.reviewCard(cardId, 2); // Blackout/Incorrect answer

        assertEquals(0, updated.getConsecutiveCorrectAnswers());
        assertEquals(1, updated.getIntervalDays());
        assertEquals(LocalDate.now().plusDays(1), updated.getNextReviewDate());
        assertTrue(updated.getEaseFactor() < 2.5f, "Ease factor should decrease when response is wrong");
    }

    @Test
    void reviewCard_ShouldProgressInterval_WhenQualityIs5() {
        UUID cardId = UUID.randomUUID();
        Flashcard card = new Flashcard();
        card.setId(cardId);
        card.setConsecutiveCorrectAnswers(1);
        card.setIntervalDays(1);
        card.setEaseFactor(2.5f);

        when(flashcardRepository.findById(cardId)).thenReturn(Optional.of(card));
        when(flashcardRepository.save(any(Flashcard.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Flashcard updated = spacedRepetitionService.reviewCard(cardId, 5);

        assertEquals(2, updated.getConsecutiveCorrectAnswers());
        assertEquals(6, updated.getIntervalDays());
        assertEquals(LocalDate.now().plusDays(6), updated.getNextReviewDate());
        assertEquals(2.6f, updated.getEaseFactor(), 0.01f, "Quality 5 should increase ease factor by 0.1");
    }

    @Test
    void reviewCard_ShouldEnforceMinimumEaseFactorFloorOf1Point3() {
        UUID cardId = UUID.randomUUID();
        Flashcard card = new Flashcard();
        card.setId(cardId);
        card.setConsecutiveCorrectAnswers(0);
        card.setIntervalDays(1);
        card.setEaseFactor(1.35f);

        when(flashcardRepository.findById(cardId)).thenReturn(Optional.of(card));
        when(flashcardRepository.save(any(Flashcard.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Quality 0 reduces ease factor significantly
        Flashcard updated = spacedRepetitionService.reviewCard(cardId, 0);

        assertEquals(1.3f, updated.getEaseFactor(), "Ease factor must never drop below floor of 1.3");
    }
}
