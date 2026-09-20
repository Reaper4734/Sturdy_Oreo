package com.oreo.engine.orchestration.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/search")
public class SearchController {

    @Value("${oreo.youtube.api.key:NONE}")
    private String youtubeApiKey;

    private final RestTemplate restTemplate = new RestTemplate();

    @GetMapping("/videos")
    public ResponseEntity<List<Map<String, Object>>> searchVideos(
            @RequestParam String topic,
            @RequestParam(required = false, defaultValue = "") String workspaceId,
            @RequestParam(required = false, defaultValue = "") String context,
            org.springframework.security.core.Authentication authentication) {
            
        List<Map<String, Object>> responseList = new ArrayList<>();
        String cleanTopic = topic != null ? topic.trim() : "";
        String cleanContext = context != null ? context.trim() : "";
        String query;
        if (cleanContext.isEmpty() || cleanContext.equalsIgnoreCase(cleanTopic)) {
            query = cleanTopic.isEmpty() ? "tutorial" : cleanTopic + " tutorial";
        } else if (cleanContext.toLowerCase().contains(cleanTopic.toLowerCase())) {
            query = cleanContext;
        } else {
            query = cleanTopic + " " + cleanContext;
        }
        
        try {
            if (!"NONE".equals(youtubeApiKey) && !youtubeApiKey.equals("mock-key") && !youtubeApiKey.isEmpty()) {
                String url = String.format("https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=3&q=%s&type=video&relevanceLanguage=en&key=%s", 
                    URLEncoder.encode(query, StandardCharsets.UTF_8.toString()), youtubeApiKey);
                
                Map<String, Object> response = restTemplate.getForObject(url, Map.class);
                if (response != null && response.containsKey("items")) {
                    List<Map<String, Object>> items = (List<Map<String, Object>>) response.get("items");
                    for (Map<String, Object> item : items) {
                        Map<String, Object> idObj = (Map<String, Object>) item.get("id");
                        Map<String, Object> snippet = (Map<String, Object>) item.get("snippet");
                        String videoId = (String) idObj.get("videoId");
                        if (videoId == null || videoId.isEmpty()) continue;
                        String title = (String) snippet.get("title");
                        String channelTitle = (String) snippet.get("channelTitle");

                        String thumbnailUrl = "https://img.youtube.com/vi/" + videoId + "/hqdefault.jpg";
                        if (snippet.containsKey("thumbnails") && snippet.get("thumbnails") instanceof Map) {
                            Map<?, ?> thumbs = (Map<?, ?>) snippet.get("thumbnails");
                            if (thumbs.get("medium") instanceof Map) {
                                Object u = ((Map<?, ?>) thumbs.get("medium")).get("url");
                                if (u != null) thumbnailUrl = u.toString();
                            } else if (thumbs.get("default") instanceof Map) {
                                Object u = ((Map<?, ?>) thumbs.get("default")).get("url");
                                if (u != null) thumbnailUrl = u.toString();
                            }
                        }
                        
                        responseList.add(Map.of(
                                "id", videoId,
                                "title", title != null ? title : cleanTopic,
                                "thumbnailUrl", thumbnailUrl,
                                "videoUrl", "https://www.youtube.com/watch?v=" + videoId,
                                "author", channelTitle != null ? channelTitle : "YouTube",
                                "duration", "10:00",
                                "type", "video"
                        ));
                    }
                    return ResponseEntity.ok(responseList);
                }
            }
        } catch (Exception e) {
            System.err.println("SearchController YouTube API Exception: " + e.getMessage());
        }
        
        // If API key is missing, invalid, quota exceeded, or no results returned:
        // provide curated high-quality educational video fallbacks so player is never empty.
        if (responseList.isEmpty()) {
            String lowerQuery = query.toLowerCase();
            String fallbackId;
            String fallbackTitle;
            String fallbackAuthor;

            if (lowerQuery.contains("python")) {
                fallbackId = "_uQrJ0TkZlc";
                fallbackTitle = "Python Tutorial for Beginners [Full Course]";
                fallbackAuthor = "Programming with Mosh";
            } else if (lowerQuery.contains("spring") || lowerQuery.contains("boot")) {
                fallbackId = "9SGDpanrc8U";
                fallbackTitle = "Spring Boot Full Course - Learn Spring Boot";
                fallbackAuthor = "Amigoscode";
            } else if (lowerQuery.contains("java")) {
                fallbackId = "A74TOX803D0";
                fallbackTitle = "Java Tutorial for Beginners";
                fallbackAuthor = "Programming with Mosh";
            } else if (lowerQuery.contains("flutter") || lowerQuery.contains("dart")) {
                fallbackId = "VPvVD8t02U8";
                fallbackTitle = "Flutter Crash Course for Beginners";
                fallbackAuthor = "Traversy Media";
            } else if (lowerQuery.contains("sql") || lowerQuery.contains("database")) {
                fallbackId = "HXV3zeQKqGY";
                fallbackTitle = "SQL Tutorial - Full Database Course";
                fallbackAuthor = "freeCodeCamp.org";
            } else if (lowerQuery.contains("javascript") || lowerQuery.contains("react") || lowerQuery.contains("web")) {
                fallbackId = "zJSY8tbf_ys";
                fallbackTitle = "Frontend Web Development: Complete Overview";
                fallbackAuthor = "Fireship";
            } else {
                fallbackId = "8jLOx1hD3_o";
                fallbackTitle = cleanTopic.isEmpty() ? "Computer Science Fundamentals" : cleanTopic + " - Conceptual Overview";
                fallbackAuthor = "CrashCourse";
            }

            responseList.add(Map.of(
                    "id", fallbackId,
                    "title", fallbackTitle,
                    "thumbnailUrl", "https://img.youtube.com/vi/" + fallbackId + "/hqdefault.jpg",
                    "videoUrl", "https://www.youtube.com/watch?v=" + fallbackId,
                    "author", fallbackAuthor,
                    "duration", "15:00",
                    "type", "video"
            ));
        }

        return ResponseEntity.ok(responseList);
    }
}

