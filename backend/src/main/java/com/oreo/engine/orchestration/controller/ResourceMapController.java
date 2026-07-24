package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.pipelines.ResourceMapPipeline;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.HtmlUtils;

import java.util.Map;

@RestController
@RequestMapping("/api/resource-map")
public class ResourceMapController {

    private final ResourceMapPipeline resourceMapPipeline;

    public ResourceMapController(ResourceMapPipeline resourceMapPipeline) {
        this.resourceMapPipeline = resourceMapPipeline;
    }

    @PostMapping("/generate")
    public ResponseEntity<ResourceMapPipeline.ResourceMapSchema> generateResourceMap(@RequestBody Map<String, String> payload) {
        String rawSubject = payload.getOrDefault("subject", "General Knowledge");
        String subject = HtmlUtils.htmlEscape(rawSubject);
        
        ResourceMapPipeline.ResourceMapSchema schema = resourceMapPipeline.generateResourceMap(subject);
        
        return ResponseEntity.ok(schema);
    }
}
