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
    public ResponseEntity<Map<String, String>> triggerIngestion(@RequestBody Map<String, String> payload) {
        String videoId = payload.getOrDefault("videoId", "pnWINBJ3-yA");
        UUID userId = UUID.randomUUID(); // mock
        
        autonomousIngestionService.ingestVideo(videoId, userId);
        
        return ResponseEntity.accepted().body(Map.of(
            "status", "Ingestion started", 
            "videoId", videoId,
            "topic", "/topic/ingestion/" + videoId
        ));
    }
}
