package com.oreo.engine.orchestration;

import com.oreo.engine.orchestration.model.SkillNode;
import com.oreo.engine.orchestration.pipelines.FlashcardGeneratorPipeline;
import com.oreo.engine.orchestration.pipelines.SyllabusAnalyzerPipeline;
import com.oreo.engine.orchestration.repository.FlashcardRepository;
import com.oreo.engine.orchestration.repository.SkillNodeRepository;
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
    private final SyllabusAnalyzerPipeline syllabusAnalyzer;
    private final FlashcardGeneratorPipeline flashcardGenerator;
    private final SkillNodeRepository skillNodeRepository;
    private final FlashcardRepository flashcardRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public AutonomousIngestionService(
            YouTubeTranscriptService transcriptService,
            SyllabusAnalyzerPipeline syllabusAnalyzer,
            FlashcardGeneratorPipeline flashcardGenerator,
            SkillNodeRepository skillNodeRepository,
            FlashcardRepository flashcardRepository,
            SimpMessagingTemplate messagingTemplate) {
        this.transcriptService = transcriptService;
        this.syllabusAnalyzer = syllabusAnalyzer;
        this.flashcardGenerator = flashcardGenerator;
        this.skillNodeRepository = skillNodeRepository;
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

            // Step 2: Syllabus DAG
            messagingTemplate.convertAndSend(topic, Map.of("step", "SYLLABUS", "status", "Generating DAG..."));
            var skills = syllabusAnalyzer.generateTreeFromText(transcript);
            for (int i = 0; i < skills.size(); i++) {
                SyllabusAnalyzerPipeline.ExtractedSkill ex = skills.get(i);
                SkillNode node = new SkillNode();
                node.setUserId(userId);
                node.setTitle(ex.title);
                node.setDescription(ex.description);
                node.setStatus(i == 0 ? SkillNode.NodeStatus.ACTIVE : SkillNode.NodeStatus.LOCKED);
                node.setPrerequisiteIds(String.join(",", ex.prerequisiteTitles));
                skillNodeRepository.save(node);
            }
            messagingTemplate.convertAndSend(topic, Map.of("step", "SYLLABUS", "status", "Done", "nodesCreated", skills.size()));

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
