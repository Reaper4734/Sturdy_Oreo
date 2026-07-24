package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.pipelines.AssessmentAssistant;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/orchestration/assessments")
public class AssessmentController {

    private final AssessmentAssistant assessmentAssistant;

    public AssessmentController(ChatLanguageModel chatLanguageModel) {
        this.assessmentAssistant = AiServices.builder(AssessmentAssistant.class)
                .chatLanguageModel(chatLanguageModel)
                .build();
    }

    @PostMapping("/generate")
    public ResponseEntity<AssessmentAssistant.AssessmentPayload> generateAssessment(@RequestBody Map<String, String> payload) {
        String topic = payload.get("topic");
        AssessmentAssistant.AssessmentPayload assessment = assessmentAssistant.generateAssessment(topic);
        return ResponseEntity.ok(assessment);
    }

    @PostMapping("/evaluate")
    public ResponseEntity<AssessmentAssistant.EvaluationResult> evaluateAnswer(@RequestBody Map<String, String> payload) {
        String question = payload.get("question");
        String userAnswer = payload.get("userAnswer");
        
        String gradingPrompt = String.format("Question: %s\nStudent Answer: %s", question, userAnswer);
        
        AssessmentAssistant.EvaluationResult result = assessmentAssistant.evaluateAnswer(gradingPrompt);
        return ResponseEntity.ok(result);
    }
}
