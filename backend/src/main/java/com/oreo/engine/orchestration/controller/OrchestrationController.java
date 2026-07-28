package com.oreo.engine.orchestration.controller;


import com.oreo.engine.orchestration.pipelines.DynamicProfilerPipeline;
import com.oreo.engine.orchestration.pipelines.SandboxExplainerPipeline;
import com.oreo.engine.orchestration.schemas.ProfilerOutputSchema;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

import com.oreo.auth.User;
import com.oreo.auth.UserRepository;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

@RestController
@RequestMapping("/api/orchestration")
public class OrchestrationController {

    private final DynamicProfilerPipeline dynamicProfilerPipeline;
    private final SandboxExplainerPipeline sandboxExplainerPipeline;
    private final UserRepository userRepository;

    public OrchestrationController(
            DynamicProfilerPipeline dynamicProfilerPipeline,
            SandboxExplainerPipeline sandboxExplainerPipeline,
            UserRepository userRepository) {
        this.dynamicProfilerPipeline = dynamicProfilerPipeline;
        this.sandboxExplainerPipeline = sandboxExplainerPipeline;
        this.userRepository = userRepository;
    }

    @PostMapping("/interview")
    public ResponseEntity<ProfilerOutputSchema> triggerInterview(@RequestBody Map<String, String> payload) {
        String userInput = payload.getOrDefault("message", "I want to learn Spring Boot");
        String history = payload.getOrDefault("history", "No prior history.");
        return ResponseEntity.ok(dynamicProfilerPipeline.run(history, userInput));
    }

    @PostMapping("/interview/complete")
    public ResponseEntity<Map<String, String>> completeInterview(
            @AuthenticationPrincipal String userId,
            @RequestBody Map<String, String> payload) {
        
        User user = userRepository.findById(UUID.fromString(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
                
        user.setDomain(payload.get("domain"));
        user.setIqLogic(payload.get("iqLogic"));
        user.setEqResilience(payload.get("eqResilience"));
        user.setCurrentPhase("EXECUTION");
        
        userRepository.save(user);
        
        return ResponseEntity.ok(Map.of("status", "success", "message", "User persona permanently saved."));
    }


    @PostMapping("/canvas-explain")
    public ResponseEntity<Map<String, String>> triggerCanvasExplain(@RequestBody Map<String, Object> payload) {
        String rawDoubt = (String) payload.getOrDefault("doubt", "");
        String doubt = org.springframework.web.util.HtmlUtils.htmlEscape(rawDoubt); // Sanitization
        
        Integer difficultyLevel = payload.containsKey("difficultyLevel") ? (Integer) payload.get("difficultyLevel") : 3;
        
        Double videoTimestamp = -1.0;
        if (payload.containsKey("videoTimestamp")) {
            Object vt = payload.get("videoTimestamp");
            videoTimestamp = vt instanceof Number ? ((Number) vt).doubleValue() : Double.parseDouble(vt.toString());
        }
        
        String rawVideoId = (String) payload.getOrDefault("videoId", "unknown");
        String videoId = org.springframework.web.util.HtmlUtils.htmlEscape(rawVideoId);

        String sessionIdStr = (String) payload.getOrDefault("sessionId", "11111111-1111-1111-1111-111111111111");
        UUID userId;
        try {
            userId = UUID.fromString(sessionIdStr);
        } catch (Exception e) {
            userId = UUID.fromString("11111111-1111-1111-1111-111111111111");
        }

        String language = (String) payload.getOrDefault("language", "en");
        String imageBase64 = (String) payload.get("imageBase64");

        return ResponseEntity.ok(sandboxExplainerPipeline.explain(userId, doubt, videoTimestamp, videoId, language, difficultyLevel, imageBase64));
    }

}
