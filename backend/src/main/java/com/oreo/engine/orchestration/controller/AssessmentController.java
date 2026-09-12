package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.pipelines.AssessmentAiService;
import com.oreo.engine.orchestration.schemas.AssessmentEvaluationSchema;
import com.oreo.engine.orchestration.schemas.AssessmentGenerationSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import jakarta.annotation.PostConstruct;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/orchestration/assessments")
public class AssessmentController {

    private final ChatLanguageModel primaryChatModel;
    private final com.oreo.engine.orchestration.SpacedRepetitionService spacedRepetitionService;
    private AssessmentAiService assessmentAiService;
    private com.oreo.engine.orchestration.pipelines.FlashcardAiService flashcardAiService;

    public AssessmentController(ChatLanguageModel primaryChatModel, com.oreo.engine.orchestration.SpacedRepetitionService spacedRepetitionService) {
        this.primaryChatModel = primaryChatModel;
        this.spacedRepetitionService = spacedRepetitionService;
    }

    @PostConstruct
    public void init() {
        this.assessmentAiService = AiServices.builder(AssessmentAiService.class)
                .chatLanguageModel(primaryChatModel)
                .build();
        this.flashcardAiService = AiServices.builder(com.oreo.engine.orchestration.pipelines.FlashcardAiService.class)
                .chatLanguageModel(primaryChatModel)
                .build();
    }

    @PostMapping("/flashcards")
    public ResponseEntity<com.oreo.engine.orchestration.schemas.FlashcardGenerationSchema> generateFlashcards(@RequestBody Map<String, String> payload) {
        String topic = payload.get("topic");
        if (topic == null || topic.trim().isEmpty()) {
            throw new IllegalArgumentException("Topic is required for flashcard generation.");
        }
        com.oreo.engine.orchestration.schemas.FlashcardGenerationSchema response = flashcardAiService.generateFlashcards("Topic: " + topic.trim());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/flashcards/{cardId}/review")
    public ResponseEntity<com.oreo.engine.orchestration.model.Flashcard> reviewCard(
            @PathVariable java.util.UUID cardId,
            @RequestBody Map<String, Integer> payload) {
        int quality = payload.getOrDefault("quality", 3);
        return ResponseEntity.ok(spacedRepetitionService.reviewCard(cardId, quality));
    }

    @PostMapping("/generate")
    public ResponseEntity<AssessmentGenerationSchema> generateAssessment(@RequestBody Map<String, String> payload) {
        String topic = payload.get("topic");
        if (topic == null || topic.trim().isEmpty()) {
            throw new IllegalArgumentException("Topic is required for assessment generation.");
        }
        AssessmentGenerationSchema response = assessmentAiService.generateAssessment("Topic: " + topic.trim());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/evaluate")
    public ResponseEntity<AssessmentEvaluationSchema> evaluateAnswer(@RequestBody Map<String, String> payload) {
        String topic = payload.get("topic");
        String question = payload.get("question");
        String answer = payload.get("answer");

        if (topic == null || topic.trim().isEmpty()) {
            throw new IllegalArgumentException("Topic is required for answer evaluation.");
        }
        if (question == null || question.trim().isEmpty()) {
            throw new IllegalArgumentException("Question is required for answer evaluation.");
        }
        if (answer == null || answer.trim().isEmpty()) {
            throw new IllegalArgumentException("Answer is required for evaluation.");
        }
        
        String prompt = "Topic: " + topic.trim() + "\n" +
                        "Question: " + question.trim() + "\n" +
                        "Student Answer: " + answer.trim();
                        
        AssessmentEvaluationSchema response = assessmentAiService.evaluateAnswer(prompt);
        return ResponseEntity.ok(response);
    }
}
