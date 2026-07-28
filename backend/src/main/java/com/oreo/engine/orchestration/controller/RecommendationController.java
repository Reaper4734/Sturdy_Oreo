package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.pipelines.RecommendationPipeline;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.HtmlUtils;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/recommendations")
public class RecommendationController {

    private final RecommendationPipeline recommendationPipeline;

    public RecommendationController(RecommendationPipeline recommendationPipeline) {
        this.recommendationPipeline = recommendationPipeline;
    }

    @PostMapping("/generate")
    public ResponseEntity<Map<String, List<String>>> getRecommendations(@RequestBody Map<String, String> payload) {
        String rawDomain = payload.getOrDefault("domain", "General Computer Science");
        String domain = HtmlUtils.htmlEscape(rawDomain);
        
        List<String> recommendations = recommendationPipeline.getRecommendations(domain);
        
        return ResponseEntity.ok(Map.of("recommendations", recommendations));
    }
}
