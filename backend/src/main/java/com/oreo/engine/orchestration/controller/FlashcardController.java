package com.oreo.engine.orchestration.controller;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.HtmlUtils;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import com.oreo.engine.orchestration.SpacedRepetitionService;
import com.oreo.engine.orchestration.model.Flashcard;

@RestController
@RequestMapping("/api/orchestration")
public class FlashcardController {

    private final ChatLanguageModel chatLanguageModel;
    private final FlashcardGenerator generator;
    private final SpacedRepetitionService spacedRepetitionService;

    public FlashcardController(ChatLanguageModel chatLanguageModel, SpacedRepetitionService spacedRepetitionService) {
        this.chatLanguageModel = chatLanguageModel;
        this.spacedRepetitionService = spacedRepetitionService;
        this.generator = AiServices.builder(FlashcardGenerator.class)
                .chatLanguageModel(chatLanguageModel)
                .build();
    }

    interface FlashcardGenerator {
        @SystemMessage({
                "You are an AI that generates educational flashcards.",
                "Extract 3 key concepts from the following transcript and return them as flashcards.",
                "Format strictly as: Front 1: ... | Back 1: ... \n Front 2: ... | Back 2: ... \n Front 3: ... | Back 3: ..."
        })
        String generate(@UserMessage String transcript);
    }

    @PostMapping("/flashcards/generate")
    public ResponseEntity<Map<String, Object>> generateFlashcards(@RequestBody Map<String, String> payload) {
        String rawTranscript = payload.getOrDefault("transcript", "No transcript provided.");
        String transcript = HtmlUtils.htmlEscape(rawTranscript); // Sanitization

        try {
            String flashcardsRaw = generator.generate(transcript);
            List<Map<String, String>> cards = flashcardsRaw.lines()
                    .filter(l -> l.contains("|"))
                    .map(l -> {
                        String[] parts = l.split("\\|");
                        return Map.of(
                                "front", parts[0].replaceFirst("Front \\d+:", "").trim(),
                                "back", parts.length > 1 ? parts[1].replaceFirst("Back \\d+:", "").trim() : ""
                        );
                    })
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
