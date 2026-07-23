package com.oreo.engine.orchestration.controller;

import org.springframework.http.ResponseEntity;
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

    public FlashcardController(FlashcardGeneratorPipeline flashcardGeneratorPipeline, SpacedRepetitionService spacedRepetitionService) {
        this.flashcardGeneratorPipeline = flashcardGeneratorPipeline;
        this.spacedRepetitionService = spacedRepetitionService;
    }

    @PostMapping("/flashcards/generate")
    public ResponseEntity<Map<String, Object>> generateFlashcards(@RequestBody Map<String, String> payload) {
        String rawTranscript = payload.getOrDefault("transcript", "No transcript provided.");
        String transcript = HtmlUtils.htmlEscape(rawTranscript); // Sanitization

        try {
            var extractedCards = flashcardGeneratorPipeline.generateFlashcards(transcript);
            List<Map<String, String>> cards = extractedCards.stream()
                    .map(c -> Map.of("front", c.frontQuestion, "back", c.backAnswer))
                    .collect(Collectors.toList());

            return ResponseEntity.ok(Map.of("flashcards", cards));
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
