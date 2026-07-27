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
    private AssessmentAiService assessmentAiService;
    private com.oreo.engine.orchestration.pipelines.FlashcardAiService flashcardAiService;

    public AssessmentController(ChatLanguageModel primaryChatModel) {
        this.primaryChatModel = primaryChatModel;
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
        String topic = payload.getOrDefault("topic", "General Computer Science");
        com.oreo.engine.orchestration.schemas.FlashcardGenerationSchema response = flashcardAiService.generateFlashcards("Topic: " + topic);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/generate")
    public ResponseEntity<AssessmentGenerationSchema> generateAssessment(@RequestBody Map<String, String> payload) {
        String topic = payload.getOrDefault("topic", "General Computer Science");
        AssessmentGenerationSchema response = assessmentAiService.generateAssessment("Topic: " + topic);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/evaluate")
    public ResponseEntity<AssessmentEvaluationSchema> evaluateAnswer(@RequestBody Map<String, String> payload) {
        String topic = payload.getOrDefault("topic", "General Computer Science");
        String question = payload.getOrDefault("question", "");
        String answer = payload.getOrDefault("answer", "");
        
        String prompt = "Topic: " + topic + "\n" +
                        "Question: " + question + "\n" +
                        "Student Answer: " + answer;
                        
        AssessmentEvaluationSchema response = assessmentAiService.evaluateAnswer(prompt);
        return ResponseEntity.ok(response);
    }
}
