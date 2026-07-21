package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.OrchestrationService;
import com.oreo.engine.orchestration.model.OrchestrationMode;
import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/orchestration")
public class OrchestrationController {

    private final OrchestrationService orchestrationService;

    public OrchestrationController(OrchestrationService orchestrationService) {
        this.orchestrationService = orchestrationService;
    }

    @PostMapping("/interview")
    public ResponseEntity<OrchestrationResponse> triggerInterview(@RequestBody Map<String, String> payload) {
        OrchestrationRequest request = OrchestrationRequest.builder()
                .userId(UUID.randomUUID()) // Mock user ID for now
                .mode(OrchestrationMode.INTERVIEW)
                .userInput(payload.getOrDefault("message", "I want to learn Spring Boot"))
                .context(Map.of("history", payload.getOrDefault("history", "")))
                .build();
        return ResponseEntity.ok(orchestrationService.process(request));
    }

    @PostMapping("/dag-generate")
    public ResponseEntity<OrchestrationResponse> triggerDagGenerate(@RequestBody Map<String, String> payload) {
        OrchestrationRequest request = OrchestrationRequest.builder()
                .userId(UUID.randomUUID())
                .mode(OrchestrationMode.DAG_GENERATE)
                .userInput(payload.getOrDefault("goal", "Build a real-time dashboard with React"))
                .context(Map.of("persona", payload.getOrDefault("persona", "Visual learner, needs early wins")))
                .build();
        return ResponseEntity.ok(orchestrationService.process(request));
    }
}
