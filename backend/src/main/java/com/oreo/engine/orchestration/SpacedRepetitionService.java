package com.oreo.engine.orchestration;

import com.oreo.engine.orchestration.model.Flashcard;
import com.oreo.engine.orchestration.repository.FlashcardRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.UUID;

@Service
public class SpacedRepetitionService {

    private final FlashcardRepository flashcardRepository;

    public SpacedRepetitionService(FlashcardRepository flashcardRepository) {
        this.flashcardRepository = flashcardRepository;
    }

    public Flashcard reviewCard(UUID cardId, int quality) {
        Flashcard card = flashcardRepository.findById(cardId)
                .orElseThrow(() -> new IllegalArgumentException("Flashcard not found: " + cardId));

        if (quality < 3) {
            card.setConsecutiveCorrectAnswers(0);
            card.setIntervalDays(1);
        } else {
            int consecutive = card.getConsecutiveCorrectAnswers() + 1;
            card.setConsecutiveCorrectAnswers(consecutive);
            if (consecutive == 1) {
                card.setIntervalDays(1);
            } else if (consecutive == 2) {
                card.setIntervalDays(6);
            } else {
                card.setIntervalDays(Math.round(card.getIntervalDays() * card.getEaseFactor()));
            }
        }

        // SM-2 Ease Factor formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        float newEaseFactor = card.getEaseFactor() + (0.1f - (5 - quality) * (0.08f + (5 - quality) * 0.02f));
        card.setEaseFactor(Math.max(1.3f, newEaseFactor));
        card.setNextReviewDate(LocalDate.now().plusDays(card.getIntervalDays()));

        return flashcardRepository.save(card);
    }
}
