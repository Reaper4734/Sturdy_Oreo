package com.oreo.engine.orchestration;

import com.oreo.engine.orchestration.pipelines.FlashcardGeneratorPipeline;
import com.oreo.engine.orchestration.repository.FlashcardRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class AutonomousIngestionService {
    
    private static final Logger log = LoggerFactory.getLogger(AutonomousIngestionService.class);

    private final YouTubeTranscriptService transcriptService;
    private final FlashcardGeneratorPipeline flashcardGenerator;
    private final FlashcardRepository flashcardRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public AutonomousIngestionService(
            YouTubeTranscriptService transcriptService,
            FlashcardGeneratorPipeline flashcardGenerator,
            FlashcardRepository flashcardRepository,
            SimpMessagingTemplate messagingTemplate) {
        this.transcriptService = transcriptService;
        this.flashcardGenerator = flashcardGenerator;
        this.flashcardRepository = flashcardRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Async
    public void ingestVideo(String videoId, UUID userId) {
        String topic = "/topic/ingestion/" + videoId;
        log.info("Starting autonomous ingestion for video: {}", videoId);

        try {
            // Step 1: Transcript
            messagingTemplate.convertAndSend(topic, Map.of("step", "TRANSCRIPT", "status", "Downloading..."));
            // We fetch the full transcript for ingestion
            String transcript = transcriptService.getTranscriptBufferBeforeTimestamp(videoId, Integer.MAX_VALUE, Integer.MAX_VALUE).orElse("");
            messagingTemplate.convertAndSend(topic, Map.of("step", "TRANSCRIPT", "status", "Done", "length", transcript.length()));



            // Step 3: Flashcards
            messagingTemplate.convertAndSend(topic, Map.of("step", "FLASHCARDS", "status", "Extracting..."));
            var cards = flashcardGenerator.generateFlashcards(transcript, Integer.MAX_VALUE);
            for (var c : cards) {
                com.oreo.engine.orchestration.model.Flashcard f = new com.oreo.engine.orchestration.model.Flashcard();
                f.setUserId(userId);
                f.setFront(c.frontQuestion);
                f.setBack(c.backAnswer);
                flashcardRepository.save(f);
            }
            messagingTemplate.convertAndSend(topic, Map.of("step", "FLASHCARDS", "status", "Done", "cardsCreated", cards.size()));

            messagingTemplate.convertAndSend(topic, Map.of("step", "COMPLETE", "status", "Ingestion Finished Successfully"));
            log.info("Finished autonomous ingestion for video: {}", videoId);

        } catch (Exception e) {
            log.error("Failed to ingest video: {}", videoId, e);
            messagingTemplate.convertAndSend(topic, Map.of("step", "ERROR", "message", e.getMessage()));
        }
    }
}
