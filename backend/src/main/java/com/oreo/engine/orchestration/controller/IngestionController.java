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

        UUID userUuid = (userId != null && !userId.isBlank())
                ? UUID.fromString(userId)
                : UUID.nameUUIDFromBytes(videoId.getBytes());

        autonomousIngestionService.ingestVideo(videoId.trim(), userUuid);

        return ResponseEntity.accepted().body(Map.of(
            "status", "Ingestion started",
            "videoId", videoId.trim(),
            "topic", "/topic/ingestion/" + videoId.trim()
        ));
    }
}
