package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.AutonomousIngestionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/orchestration")
public class IngestionController {

    private final AutonomousIngestionService autonomousIngestionService;

    public IngestionController(AutonomousIngestionService autonomousIngestionService) {
        this.autonomousIngestionService = autonomousIngestionService;
    }

    @PostMapping("/ingest")
    public ResponseEntity<Map<String, String>> triggerIngestion(
            @org.springframework.security.core.annotation.AuthenticationPrincipal String userId,
            @RequestBody Map<String, String> payload) {
        String videoId = payload.get("videoId");
        if (videoId == null || videoId.trim().isEmpty()) {
            throw new IllegalArgumentException("videoId is required for ingestion.");
        }

        UUID userUuid;
        if (userId != null && !userId.isBlank() && !"anonymousUser".equalsIgnoreCase(userId)) {
            try {
                userUuid = UUID.fromString(userId);
            } catch (IllegalArgumentException e) {
                userUuid = UUID.nameUUIDFromBytes(userId.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            }
        } else {
            userUuid = UUID.nameUUIDFromBytes(videoId.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        }

        autonomousIngestionService.ingestVideo(videoId.trim(), userUuid);

        return ResponseEntity.accepted().body(Map.of(
            "status", "Ingestion started",
            "videoId", videoId.trim(),
            "topic", "/topic/ingestion/" + videoId.trim()
        ));
    }
}
