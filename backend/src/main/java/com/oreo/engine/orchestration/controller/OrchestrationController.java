package com.oreo.engine.orchestration.controller;


import com.oreo.engine.orchestration.pipelines.DynamicProfilerPipeline;
import com.oreo.engine.orchestration.pipelines.DagGeneratorPipeline;
import com.oreo.engine.orchestration.pipelines.SandboxExplainerPipeline;
import com.oreo.engine.orchestration.schemas.DagOutputSchema;
import com.oreo.engine.orchestration.schemas.ProfilerOutputSchema;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/orchestration")
public class OrchestrationController {

    private final DynamicProfilerPipeline dynamicProfilerPipeline;
    private final DagGeneratorPipeline dagGeneratorPipeline;
    private final SandboxExplainerPipeline sandboxExplainerPipeline;
    public OrchestrationController(
            DynamicProfilerPipeline dynamicProfilerPipeline,
            DagGeneratorPipeline dagGeneratorPipeline,
            SandboxExplainerPipeline sandboxExplainerPipeline) {
        this.dynamicProfilerPipeline = dynamicProfilerPipeline;
        this.dagGeneratorPipeline = dagGeneratorPipeline;
        this.sandboxExplainerPipeline = sandboxExplainerPipeline;
    }

    @PostMapping("/interview")
    public ResponseEntity<ProfilerOutputSchema> triggerInterview(@RequestBody Map<String, String> payload) {
        String userInput = payload.getOrDefault("message", "I want to learn Spring Boot");
        String history = payload.getOrDefault("history", "No prior history.");
        return ResponseEntity.ok(dynamicProfilerPipeline.run(history, userInput));
    }

    @PostMapping("/dag-generate")
    public ResponseEntity<DagOutputSchema> triggerDagGenerate(@RequestBody Map<String, String> payload) {
        String goal = payload.getOrDefault("goal", "Build a real-time dashboard with React");
        String persona = payload.getOrDefault("persona", "Visual learner, needs early wins");
        UUID userId = UUID.randomUUID(); // Mock user ID for now
        
        DagOutputSchema schema = dagGeneratorPipeline.generate(goal, persona, userId);
        
        return ResponseEntity.ok(schema);
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

        String rawLanguage = (String) payload.getOrDefault("language", "en");
        String language = org.springframework.web.util.HtmlUtils.htmlEscape(rawLanguage);

        return ResponseEntity.ok(sandboxExplainerPipeline.explain(userId, doubt, videoTimestamp, videoId, language, difficultyLevel));
    }

}
