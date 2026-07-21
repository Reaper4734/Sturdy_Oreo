package com.oreo.engine.orchestration;

import com.oreo.engine.orchestration.model.Flashcard;
import com.oreo.engine.orchestration.repository.FlashcardRepository;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.logging.Logger;

@Service
public class SpacedRepetitionService {

    private static final Logger logger = Logger.getLogger(SpacedRepetitionService.class.getName());
    private final FlashcardRepository flashcardRepository;

    public SpacedRepetitionService(FlashcardRepository flashcardRepository) {
        this.flashcardRepository = flashcardRepository;
    }

    /**
     * Applies the SuperMemo-2 (SM-2) algorithm.
     * Quality: 0=Blackout, 3=Hard, 4=Good, 5=Perfect
     */
    public Flashcard reviewCard(UUID cardId, int quality) {
        Flashcard card = flashcardRepository.findById(cardId).orElseThrow();
        
        if (quality < 3) {
            card.setConsecutiveCorrectAnswers(0);
            card.setIntervalDays(1);
        } else {
            int correct = card.getConsecutiveCorrectAnswers() + 1;
            card.setConsecutiveCorrectAnswers(correct);
            
            if (correct == 1) {
                card.setIntervalDays(1);
            } else if (correct == 2) {
                card.setIntervalDays(6);
            } else {
                card.setIntervalDays(Math.round(card.getIntervalDays() * card.getEaseFactor()));
            }
        }

        float newEase = card.getEaseFactor() + (0.1f - (5 - quality) * (0.08f + (5 - quality) * 0.02f));
        if (newEase < 1.3f) newEase = 1.3f;
        card.setEaseFactor(newEase);

        card.setNextReviewDate(LocalDate.now().plusDays(card.getIntervalDays()));
        return flashcardRepository.save(card);
    }

    /**
     * Background Job to notify users of due flashcards.
     * Runs every day at 8:00 AM server time.
     */
    @Scheduled(cron = "0 0 8 * * ?")
    public void notifyDueFlashcards() {
        logger.info("Scanning for due flashcards...");
        // In a real implementation, we'd query distinct users with due cards and push Firebase notifications.
        // List<Flashcard> dueCards = flashcardRepository.findByUserIdAndNextReviewDateLessThanEqual(..., LocalDate.now());
    }
}
