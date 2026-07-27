package com.oreo.engine.orchestration.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.ArrayList;

@RestController
@RequestMapping("/api/search")
public class SearchController {

    @GetMapping("/videos")
    public ResponseEntity<List<Map<String, Object>>> searchVideos(
            @RequestParam String topic,
            org.springframework.security.core.Authentication authentication) {
            
        // Mock video search results for the given topic
        List<Map<String, Object>> videos = new ArrayList<>();
        
        videos.add(Map.of(
                "id", UUID.randomUUID().toString(),
                "title", topic + " - Full Course for Beginners",
                "thumbnailUrl", "https://img.youtube.com/vi/bJzb-RuUcMU/maxresdefault.jpg",
                "videoUrl", "https://www.youtube.com/watch?v=bJzb-RuUcMU",
                "author", "Tech Academy",
                "duration", "2:15:00",
                "type", "video"
        ));
        
        videos.add(Map.of(
                "id", UUID.randomUUID().toString(),
                "title", "10 Things You Didn't Know About " + topic,
                "thumbnailUrl", "https://img.youtube.com/vi/bJzb-RuUcMU/hqdefault.jpg",
                "videoUrl", "https://www.youtube.com/watch?v=bJzb-RuUcMU",
                "author", "Code Master",
                "duration", "15:30",
                "type", "video"
        ));
        
        videos.add(Map.of(
                "id", UUID.randomUUID().toString(),
                "title", topic + " in 100 Seconds",
                "thumbnailUrl", "https://img.youtube.com/vi/bJzb-RuUcMU/mqdefault.jpg",
                "videoUrl", "https://www.youtube.com/watch?v=bJzb-RuUcMU",
                "author", "Fireship Mock",
                "duration", "2:05",
                "type", "video"
        ));
        
        return ResponseEntity.ok(videos);
    }
}
