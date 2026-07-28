package com.oreo.engine.orchestration.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/catalog")
public class CourseCatalogController {

    private final List<Map<String, Object>> courses = List.of(
            Map.of("id", "c1", "title", "Spring Boot Microservices", "category", "Backend", "difficulty", "Advanced", "tags", List.of("Java", "Spring", "Microservices"), "estimatedHours", 24, "thumbnailUrl", ""),
            Map.of("id", "c2", "title", "React Native for Mobile", "category", "Frontend", "difficulty", "Intermediate", "tags", List.of("React", "Mobile"), "estimatedHours", 18, "thumbnailUrl", ""),
            Map.of("id", "c3", "title", "Python Data Science", "category", "Data", "difficulty", "Beginner", "tags", List.of("Python", "Pandas", "ML"), "estimatedHours", 40, "thumbnailUrl", ""),
            Map.of("id", "c4", "title", "PostgreSQL Optimization", "category", "Database", "difficulty", "Advanced", "tags", List.of("SQL", "Performance"), "estimatedHours", 12, "thumbnailUrl", "")
    );

    @GetMapping("/all")
    public ResponseEntity<List<Map<String, Object>>> getAllCourses() {
        return ResponseEntity.ok(courses);
    }

    @GetMapping("/recommendations")
    public ResponseEntity<List<Map<String, Object>>> getRecommendations(@RequestParam(required = false) String domain) {
        return ResponseEntity.ok(courses.subList(0, Math.min(2, courses.size())));
    }
    
    @GetMapping("/search")
    public ResponseEntity<List<Map<String, Object>>> searchCourses(@RequestParam String query) {
        if (query == null || query.isBlank()) return ResponseEntity.ok(courses);
        String q = query.toLowerCase();
        List<Map<String, Object>> filtered = courses.stream()
            .filter(c -> c.get("title").toString().toLowerCase().contains(q) || c.get("category").toString().toLowerCase().contains(q))
            .collect(Collectors.toList());
        return ResponseEntity.ok(filtered);
    }
}
