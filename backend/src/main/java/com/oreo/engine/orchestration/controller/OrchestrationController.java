package com.oreo.engine.orchestration.controller;


import com.oreo.engine.orchestration.pipelines.DynamicProfilerPipeline;
import com.oreo.engine.orchestration.pipelines.SandboxExplainerPipeline;
<<<<<<< HEAD
import com.oreo.engine.orchestration.schemas.ProfilerOutputSchema;
=======
import com.oreo.engine.orchestration.pipelines.RoadmapUpdatePipeline;
import com.oreo.engine.orchestration.schemas.DagOutputSchema;
import com.oreo.engine.orchestration.model.OrchestrationMode;
import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import com.oreo.engine.orchestration.schemas.KnowledgeGraphSchema;
import com.oreo.engine.orchestration.services.DagBuilder;
import com.oreo.engine.orchestration.services.GraphOptimizer;
import com.oreo.engine.orchestration.services.GraphValidator;
>>>>>>> origin/master
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
<<<<<<< HEAD
=======
    private final RoadmapUpdatePipeline roadmapUpdatePipeline;
    private final LearningTrackRepository trackRepository;
>>>>>>> origin/master
    private final UserRepository userRepository;
    private final DagBuilder dagBuilder;
    private final GraphValidator graphValidator;
    private final GraphOptimizer graphOptimizer;

    public OrchestrationController(
            DynamicProfilerPipeline dynamicProfilerPipeline,
            SandboxExplainerPipeline sandboxExplainerPipeline,
<<<<<<< HEAD
            UserRepository userRepository) {
=======
            RoadmapUpdatePipeline roadmapUpdatePipeline,
            LearningTrackRepository trackRepository,
            UserRepository userRepository,
            DagBuilder dagBuilder,
            GraphValidator graphValidator,
            GraphOptimizer graphOptimizer) {
>>>>>>> origin/master
        this.dynamicProfilerPipeline = dynamicProfilerPipeline;
        this.sandboxExplainerPipeline = sandboxExplainerPipeline;
<<<<<<< HEAD
=======
        this.roadmapUpdatePipeline = roadmapUpdatePipeline;
        this.trackRepository = trackRepository;
>>>>>>> origin/master
        this.userRepository = userRepository;
        this.dagBuilder = dagBuilder;
        this.graphValidator = graphValidator;
        this.graphOptimizer = graphOptimizer;
    }

    @PostMapping("/interview")
    public ResponseEntity<ProfilerOutputSchema> triggerInterview(@RequestBody Map<String, String> payload) {
        String userInput = payload.getOrDefault("message", "I want to learn Spring Boot");
        String history = payload.getOrDefault("history", "No prior history.");
        return ResponseEntity.ok(dynamicProfilerPipeline.run(history, userInput));
    }

<<<<<<< HEAD
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
=======
    @PostMapping("/dag-generate")
    public ResponseEntity<OrchestrationResponse> triggerDagGenerate(@RequestBody Map<String, String> payload) {
        OrchestrationRequest request = OrchestrationRequest.builder()
                .userId(UUID.randomUUID())
                .mode(OrchestrationMode.DAG_GENERATE)
                .userInput(payload.getOrDefault("goal", "Build a real-time dashboard with React"))
                .context(Map.of("persona", payload.getOrDefault("persona", "Visual learner, needs early wins")))
                .build();
        OrchestrationResponse response = null;
        KnowledgeGraphSchema kg = null;
        
        try {
            response = dagGeneratorPipeline.run(request);
            if (response.getPayload() instanceof DagOutputSchema schema) {
                kg = dagBuilder.buildKnowledgeGraph(schema);
                graphValidator.validate(kg);
                kg = graphOptimizer.optimize(kg);
                response.setPayload(kg);
            }
        } catch (Exception e) {
            // Retry strategy (1x)
            System.err.println("Graph validation failed, retrying... " + e.getMessage());
            response = dagGeneratorPipeline.run(request);
            if (response.getPayload() instanceof DagOutputSchema schema) {
                kg = dagBuilder.buildKnowledgeGraph(schema);
                graphValidator.validate(kg);
                kg = graphOptimizer.optimize(kg);
                response.setPayload(kg);
            }
        }
        
        if (kg != null) {
            User user = userRepository.findById(request.getUserId()).orElse(null);
            if (user != null) {
                LearningTrack track = new LearningTrack();
                track.setUser(user);
                track.setGoal(kg.getCourseTitle() != null ? kg.getCourseTitle() : request.getUserInput());
                track.setNodes(kg.getNodes());
                track.setEdges(kg.getEdges());
                track.setCourseTitle(kg.getCourseTitle());
                track.setDifficulty(kg.getDifficulty());
                track.setEstimatedHours(kg.getEstimatedHours());
                track.setGraphType(kg.getGraphType());
                trackRepository.save(track);
            }
        }
>>>>>>> origin/master
        
        userRepository.save(user);
        
        return ResponseEntity.ok(Map.of("status", "success", "message", "User persona permanently saved."));
    }

<<<<<<< HEAD
=======
    @PostMapping("/roadmap/update")
    public ResponseEntity<OrchestrationResponse> updateRoadmap(
            @RequestBody Map<String, Object> payload,
            org.springframework.security.core.Authentication authentication) {
        
        UUID userId = authentication != null ? (UUID) authentication.getPrincipal() : UUID.randomUUID();
        String chatRequest = (String) payload.getOrDefault("request", "");
        
        // Convert the generic map back to DagOutputSchema (assuming the client sends the current workspace's dag)
        com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
        DagOutputSchema currentDag = mapper.convertValue(payload.get("currentDag"), DagOutputSchema.class);

        OrchestrationRequest request = OrchestrationRequest.builder()
                .userId(userId)
                .mode(OrchestrationMode.DAG_GENERATE)
                .userInput(chatRequest)
                .build();
                
        OrchestrationResponse response = null;
        KnowledgeGraphSchema kg = null;
        String trackIdStr = null;
        
        try {
            response = roadmapUpdatePipeline.run(request, currentDag);
            if (response.getPayload() instanceof DagOutputSchema schema) {
                trackIdStr = schema.getTrackId();
                kg = dagBuilder.buildKnowledgeGraph(schema);
                graphValidator.validate(kg);
                kg = graphOptimizer.optimize(kg);
                response.setPayload(kg);
            }
        } catch (Exception e) {
            System.err.println("Graph validation failed in update, retrying... " + e.getMessage());
            response = roadmapUpdatePipeline.run(request, currentDag);
            if (response.getPayload() instanceof DagOutputSchema schema) {
                trackIdStr = schema.getTrackId();
                kg = dagBuilder.buildKnowledgeGraph(schema);
                graphValidator.validate(kg);
                kg = graphOptimizer.optimize(kg);
                response.setPayload(kg);
            }
        }
        
        if (kg != null && trackIdStr != null) {
            try {
                UUID trackId = UUID.fromString(trackIdStr);
                LearningTrack track = trackRepository.findById(trackId).orElse(null);
                if (track != null) {
                    track.setNodes(kg.getNodes());
                    track.setEdges(kg.getEdges());
                    trackRepository.save(track);
                }
            } catch (Exception ignored) {}
        }
        
        return ResponseEntity.ok(response);
    }
>>>>>>> origin/master

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

<<<<<<< HEAD
=======
    @GetMapping("/learning-tracks")
    public ResponseEntity<java.util.List<LearningTrack>> getLearningTracks(org.springframework.security.core.Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        User user = userRepository.findById(userId).orElseThrow();
        return ResponseEntity.ok(trackRepository.findByUserId(userId));
    }

    @GetMapping("/learning-tracks/{id}")
    public ResponseEntity<LearningTrack> getLearningTrack(@PathVariable UUID id, org.springframework.security.core.Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        LearningTrack track = trackRepository.findById(id).orElseThrow();
        if (!track.getUser().getId().equals(userId)) {
            return ResponseEntity.status(403).build();
        }
        return ResponseEntity.ok(track);
    }
>>>>>>> origin/master
}
