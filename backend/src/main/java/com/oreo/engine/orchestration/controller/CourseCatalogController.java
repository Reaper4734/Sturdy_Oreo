package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.model.Workspace;
import com.oreo.engine.orchestration.pipelines.RecommendationPipeline;
import com.oreo.engine.orchestration.repository.WorkspaceRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/catalog")
public class CourseCatalogController {

    private final WorkspaceRepository workspaceRepository;
    private final RecommendationPipeline recommendationPipeline;

    public CourseCatalogController(WorkspaceRepository workspaceRepository, RecommendationPipeline recommendationPipeline) {
        this.workspaceRepository = workspaceRepository;
        this.recommendationPipeline = recommendationPipeline;
    }

    @GetMapping("/all")
    public ResponseEntity<List<Map<String, Object>>> getAllCourses() {
        List<Workspace> workspaces = workspaceRepository.findAll();
        List<Map<String, Object>> courses = new ArrayList<>();

        for (Workspace ws : workspaces) {
            Map<String, Object> data = ws.getData() != null ? ws.getData() : Map.of();
            Map<String, Object> entry = new HashMap<>();
            entry.put("id", ws.getId());
            entry.put("title", ws.getTitle());
            entry.put("category", data.getOrDefault("domain", "Technology"));
            entry.put("difficulty", data.getOrDefault("difficulty", "Intermediate"));
            entry.put("tags", extractTags(data, ws.getTitle()));
            entry.put("estimatedHours", calculateEstimatedHours(data));
            entry.put("thumbnailUrl", data.getOrDefault("thumbnailUrl", ""));
            courses.add(entry);
        }

        // If no workspaces exist yet in database, dynamically generate curated courses via recommendation pipeline
        if (courses.isEmpty()) {
            List<String> dynamicSubjects = recommendationPipeline.getRecommendations("Computer Science");
            int idx = 1;
            for (String subj : dynamicSubjects) {
                Map<String, Object> entry = new HashMap<>();
                entry.put("id", "rec_" + idx++);
                entry.put("title", subj);
                entry.put("category", "Computer Science");
                entry.put("difficulty", "Intermediate");
                entry.put("tags", List.of(subj, "Foundations"));
                entry.put("estimatedHours", 20);
                entry.put("thumbnailUrl", "");
                courses.add(entry);
            }
        }

        return ResponseEntity.ok(courses);
    }

    @GetMapping("/recommendations")
    public ResponseEntity<List<Map<String, Object>>> getRecommendations(@RequestParam(required = false) String domain) {
        String targetDomain = (domain != null && !domain.isBlank()) ? domain : "Software Engineering";
        List<String> recommendedSubjects = recommendationPipeline.getRecommendations(targetDomain);

        List<Map<String, Object>> recommendations = new ArrayList<>();
        int idCounter = 1;
        for (String subject : recommendedSubjects) {
            Map<String, Object> rec = new HashMap<>();
            rec.put("id", "rec_" + targetDomain.replaceAll("\\s+", "_").toLowerCase() + "_" + (idCounter++));
            rec.put("title", subject);
            rec.put("category", targetDomain);
            rec.put("difficulty", "Intermediate");
            rec.put("tags", List.of(targetDomain, subject));
            rec.put("estimatedHours", 15);
            rec.put("thumbnailUrl", "");
            recommendations.add(rec);
        }

        return ResponseEntity.ok(recommendations);
    }
    
    @GetMapping("/search")
    public ResponseEntity<List<Map<String, Object>>> searchCourses(@RequestParam String query) {
        if (query == null || query.isBlank()) {
            return getAllCourses();
        }

        String q = query.toLowerCase().trim();
        List<Workspace> workspaces = workspaceRepository.findAll();
        List<Map<String, Object>> matches = workspaces.stream()
                .filter(w -> {
                    String title = w.getTitle() != null ? w.getTitle().toLowerCase() : "";
                    Map<String, Object> data = w.getData() != null ? w.getData() : Map.of();
                    String subject = data.getOrDefault("subject", "").toString().toLowerCase();
                    String domain = data.getOrDefault("domain", "").toString().toLowerCase();
                    return title.contains(q) || subject.contains(q) || domain.contains(q);
                })
                .map(ws -> {
                    Map<String, Object> data = ws.getData() != null ? ws.getData() : Map.of();
                    Map<String, Object> entry = new HashMap<>();
                    entry.put("id", ws.getId());
                    entry.put("title", ws.getTitle());
                    entry.put("category", data.getOrDefault("domain", "Technology"));
                    entry.put("difficulty", data.getOrDefault("difficulty", "Intermediate"));
                    entry.put("tags", extractTags(data, ws.getTitle()));
                    entry.put("estimatedHours", calculateEstimatedHours(data));
                    entry.put("thumbnailUrl", data.getOrDefault("thumbnailUrl", ""));
                    return entry;
                })
                .collect(Collectors.toList());

        // If no workspaces matched, query LLM recommendations for that query topic dynamically
        if (matches.isEmpty()) {
            List<String> dynamicMatches = recommendationPipeline.getRecommendations(query);
            for (String sub : dynamicMatches) {
                Map<String, Object> entry = new HashMap<>();
                entry.put("id", "search_" + sub.replaceAll("\\s+", "_").toLowerCase());
                entry.put("title", sub);
                entry.put("category", query);
                entry.put("difficulty", "Intermediate");
                entry.put("tags", List.of(query, sub));
                entry.put("estimatedHours", 20);
                entry.put("thumbnailUrl", "");
                matches.add(entry);
            }
        }

        return ResponseEntity.ok(matches);
    }

    private List<String> extractTags(Map<String, Object> data, String fallback) {
        Object tagsObj = data.get("tags");
        if (tagsObj instanceof List<?>) {
            return ((List<?>) tagsObj).stream().map(Object::toString).collect(Collectors.toList());
        }
        String domain = (String) data.getOrDefault("domain", "");
        if (!domain.isEmpty()) {
            return List.of(domain, fallback);
        }
        return List.of(fallback);
    }

    private int calculateEstimatedHours(Map<String, Object> data) {
        Object roadmapObj = data.get("roadmap");
        if (roadmapObj instanceof List<?>) {
            List<?> roadmap = (List<?>) roadmapObj;
            return Math.max(5, roadmap.size() * 4);
        }
        return 16;
    }
}
