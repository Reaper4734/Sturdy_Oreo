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
    public ResponseEntity<List<Flashcard>> getAllFlashcards(
            @RequestParam(required = false) String album,
            @RequestParam(required = false) String subAlbum,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        List<Flashcard> cards = flashcardRepository.findByUserId(userId);
        
        if (album != null) {
            cards = cards.stream()
                    .filter(c -> album.equals(c.getAlbum()))
                    .filter(c -> subAlbum == null || subAlbum.equals(c.getSubAlbum()))
                    .collect(Collectors.toList());
        }
        return ResponseEntity.ok(cards);
    }

    @GetMapping("/flashcards/albums")
    public ResponseEntity<Map<String, List<String>>> getFlashcardAlbums(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        List<Object[]> distinctAlbums = flashcardRepository.findDistinctAlbumsByUserId(userId);
        
        Map<String, List<String>> albums = distinctAlbums.stream()
                .collect(Collectors.groupingBy(
                        row -> (String) row[0],
                        Collectors.mapping(row -> (String) row[1], Collectors.filtering(s -> s != null, Collectors.toList()))
                ));
                
        return ResponseEntity.ok(albums);
    }

    @GetMapping("/flashcards/universal")
    public ResponseEntity<List<Flashcard>> getUniversalFlashcards(
            @RequestParam String album,
            @RequestParam String subAlbum) {
        return ResponseEntity.ok(flashcardRepository.findTop5ByAlbumAndSubAlbum(album, subAlbum));
    }

    @PostMapping("/flashcards/generate")
    public ResponseEntity<List<Flashcard>> generateFlashcards(@RequestBody Map<String, String> payload, Authentication authentication) {
        String videoId = payload.get("videoId");
        if (videoId == null) {
            return ResponseEntity.badRequest().build();
        }
        
        int timestamp = payload.containsKey("timestamp") ? Integer.parseInt(payload.get("timestamp")) : 99999;
        String album = payload.get("album");
        String subAlbum = payload.get("subAlbum");

        try {
            // Fetch the transcript for the video (passing timestamp and max 2000 words for token efficiency)
            String transcript = youtubeTranscriptService.getTranscriptBufferBeforeTimestamp(videoId, timestamp, 2000)
                    .orElse("No transcript available.");

            var extractedCards = flashcardGeneratorPipeline.generateFlashcards(transcript, timestamp);
            
            // Save to DB
            UUID userId = (UUID) authentication.getPrincipal();
            List<Flashcard> savedCards = extractedCards.stream().map(extracted -> {
                Flashcard card = new Flashcard();
                card.setUserId(userId);
                card.setFront(extracted.frontQuestion);
                card.setBack(extracted.backAnswer);
                card.setAlbum(album);
                card.setSubAlbum(subAlbum);
                card.setNextReviewDate(java.time.LocalDate.now().plusDays(1));
                card.setIntervalDays(1);
                return flashcardRepository.save(card);
            }).collect(Collectors.toList());

            return ResponseEntity.ok(savedCards);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping("/flashcards/review")
    public ResponseEntity<Flashcard> reviewFlashcard(@RequestBody Map<String, Object> payload) {
        UUID cardId = UUID.fromString(payload.get("cardId").toString());
        int quality = Integer.parseInt(payload.get("quality").toString());
        return ResponseEntity.ok(spacedRepetitionService.reviewCard(cardId, quality));
    }
}
