package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.pipelines.RagIngestionPipeline;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;


@RestController
@RequestMapping("/api/orchestration")
public class RagController {

    private final RagIngestionPipeline ragIngestionPipeline;

    public RagController(RagIngestionPipeline ragIngestionPipeline) {
        this.ragIngestionPipeline = ragIngestionPipeline;
    }

    @PostMapping("/upload-document")
    public ResponseEntity<Map<String, String>> uploadDocument(@RequestParam("file") MultipartFile file) {
        try {
            int count = ragIngestionPipeline.ingestDocument(file);

            return ResponseEntity.ok(Map.of("message", "Successfully ingested " + count + " chunks into RAG."));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Failed to upload document: " + e.getMessage()));
        }
    }
}
