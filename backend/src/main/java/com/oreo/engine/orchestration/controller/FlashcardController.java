package com.oreo.engine.orchestration.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.HtmlUtils;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import com.oreo.engine.orchestration.SpacedRepetitionService;
import com.oreo.engine.orchestration.model.Flashcard;
import com.oreo.engine.orchestration.pipelines.FlashcardGeneratorPipeline;

@RestController
@RequestMapping("/api/orchestration")
public class FlashcardController {

    private final FlashcardGeneratorPipeline flashcardGeneratorPipeline;
    private final SpacedRepetitionService spacedRepetitionService;
    private final com.oreo.engine.orchestration.repository.FlashcardRepository flashcardRepository;
    private final com.oreo.engine.orchestration.YouTubeTranscriptService youtubeTranscriptService;

    public FlashcardController(FlashcardGeneratorPipeline flashcardGeneratorPipeline, 
                               SpacedRepetitionService spacedRepetitionService,
                               com.oreo.engine.orchestration.repository.FlashcardRepository flashcardRepository,
                               com.oreo.engine.orchestration.YouTubeTranscriptService youtubeTranscriptService) {
        this.flashcardGeneratorPipeline = flashcardGeneratorPipeline;
        this.spacedRepetitionService = spacedRepetitionService;
        this.flashcardRepository = flashcardRepository;
        this.youtubeTranscriptService = youtubeTranscriptService;
    }

    @GetMapping("/flashcards")
    public ResponseEntity<List<Flashcard>> getAllFlashcards(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(flashcardRepository.findByUserId(userId));
    }

    @PostMapping("/flashcards/generate")
    public ResponseEntity<Map<String, Object>> generateFlashcards(@RequestBody Map<String, String> payload, Authentication authentication) {
        String videoId = payload.get("videoId");
        if (videoId == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "videoId is required"));
        }

        try {
            // Fetch the ENTIRE transcript for the video (passing a massive time limit)
            String transcript = youtubeTranscriptService.getTranscriptBufferBeforeTimestamp(videoId, 99999, 2000)
                    .orElse("No transcript available.");

            var extractedCards = flashcardGeneratorPipeline.generateFlashcards(transcript);
            
            // Save to DB
            UUID userId = (UUID) authentication.getPrincipal();
            List<Flashcard> savedCards = extractedCards.stream().map(extracted -> {
                Flashcard card = new Flashcard();
                card.setUserId(userId);
                card.setFront(extracted.frontQuestion);
                card.setBack(extracted.backAnswer);
                card.setNextReviewDate(java.time.LocalDate.now().plusDays(1));
                card.setIntervalDays(1);
                return flashcardRepository.save(card);
            }).collect(Collectors.toList());

            return ResponseEntity.ok(Map.of("message", "Generated and saved " + savedCards.size() + " cards."));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Failed to generate flashcards: " + e.getMessage()));
        }
    }

    @PostMapping("/flashcards/review")
    public ResponseEntity<Flashcard> reviewFlashcard(@RequestBody Map<String, Object> payload) {
        UUID cardId = UUID.fromString(payload.get("cardId").toString());
        int quality = Integer.parseInt(payload.get("quality").toString());
        return ResponseEntity.ok(spacedRepetitionService.reviewCard(cardId, quality));
    }
}
