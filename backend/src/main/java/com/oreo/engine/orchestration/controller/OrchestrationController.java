package com.oreo.engine.orchestration.controller;

import com.oreo.auth.User;
import com.oreo.auth.UserRepository;
import com.oreo.engine.orchestration.models.LearningTrack;
import com.oreo.engine.orchestration.models.LearningTrackRepository;
import com.oreo.engine.orchestration.pipelines.DynamicProfilerPipeline;
import com.oreo.engine.orchestration.pipelines.DagGeneratorPipeline;
import com.oreo.engine.orchestration.pipelines.SandboxExplainerPipeline;
import com.oreo.engine.orchestration.schemas.DagOutputSchema;
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

    private final DynamicProfilerPipeline dynamicProfilerPipeline;
    private final DagGeneratorPipeline dagGeneratorPipeline;
    private final SandboxExplainerPipeline sandboxExplainerPipeline;
    private final LearningTrackRepository trackRepository;
    private final UserRepository userRepository;

    public OrchestrationController(
            DynamicProfilerPipeline dynamicProfilerPipeline,
            DagGeneratorPipeline dagGeneratorPipeline,
            SandboxExplainerPipeline sandboxExplainerPipeline,
            LearningTrackRepository trackRepository,
            UserRepository userRepository) {
        this.dynamicProfilerPipeline = dynamicProfilerPipeline;
        this.dagGeneratorPipeline = dagGeneratorPipeline;
        this.sandboxExplainerPipeline = sandboxExplainerPipeline;
        this.trackRepository = trackRepository;
        this.userRepository = userRepository;
    }

    @PostMapping("/interview")
    public ResponseEntity<OrchestrationResponse> triggerInterview(@RequestBody Map<String, String> payload) {
        OrchestrationRequest request = OrchestrationRequest.builder()
                .userId(UUID.randomUUID()) // Mock user ID for now
                .mode(OrchestrationMode.INTERVIEW)
                .userInput(payload.getOrDefault("message", "I want to learn Spring Boot"))
                .context(Map.of("history", payload.getOrDefault("history", "")))
                .build();
        return ResponseEntity.ok(dynamicProfilerPipeline.run(request));
    }

    @PostMapping("/dag-generate")
    public ResponseEntity<OrchestrationResponse> triggerDagGenerate(@RequestBody Map<String, String> payload) {
        OrchestrationRequest request = OrchestrationRequest.builder()
                .userId(UUID.randomUUID())
                .mode(OrchestrationMode.DAG_GENERATE)
                .userInput(payload.getOrDefault("goal", "Build a real-time dashboard with React"))
                .context(Map.of("persona", payload.getOrDefault("persona", "Visual learner, needs early wins")))
                .build();
        OrchestrationResponse response = dagGeneratorPipeline.run(request);
        
        if (response.getPayload() instanceof DagOutputSchema schema) {
            User user = userRepository.findById(request.getUserId()).orElse(null);
            if (user != null) {
                LearningTrack track = new LearningTrack();
                track.setUser(user);
                track.setGoal(schema.getGoal() != null ? schema.getGoal() : request.getUserInput());
                track.setNodes(schema.getNodes());
                trackRepository.save(track);
            }
        }
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/canvas-explain")
    public ResponseEntity<OrchestrationResponse> triggerCanvasExplain(@RequestBody Map<String, Object> payload) {
        String rawDoubt = (String) payload.getOrDefault("doubt", "");
        String doubt = org.springframework.web.util.HtmlUtils.htmlEscape(rawDoubt); // Sanitization
        
        String transcript = (String) payload.getOrDefault("transcript", "");
        Integer difficultyLevel = payload.containsKey("difficultyLevel") ? (Integer) payload.get("difficultyLevel") : 3;
        
        Double videoTimestamp = null;
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

        String rawLanguage = (String) payload.getOrDefault("language", "hi");
        String language = org.springframework.web.util.HtmlUtils.htmlEscape(rawLanguage);

        OrchestrationRequest request = OrchestrationRequest.builder()
                .userId(userId)
                .mode(OrchestrationMode.CANVAS_EXPLAIN)
                .userInput(doubt)
                .context(Map.of(
                        "transcript", transcript,
                        "difficultyLevel", difficultyLevel,
                        "videoTimestamp", videoTimestamp != null ? videoTimestamp : -1.0,
                        "videoId", videoId,
                        "language", language
                ))
                .build();
        return ResponseEntity.ok(sandboxExplainerPipeline.run(request));
    }
}
