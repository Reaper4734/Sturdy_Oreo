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
        String query = topic + (context.isEmpty() ? "" : " " + context);
        
        try {
            if (!"NONE".equals(youtubeApiKey) && !youtubeApiKey.equals("mock-key") && !youtubeApiKey.isEmpty()) {
                String url = String.format("https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=3&q=%s&type=video&videoDuration=medium&key=%s", 
                    URLEncoder.encode(query, StandardCharsets.UTF_8.toString()), youtubeApiKey);
                
                Map<String, Object> response = restTemplate.getForObject(url, Map.class);
                if (response != null && response.containsKey("items")) {
                    List<Map<String, Object>> items = (List<Map<String, Object>>) response.get("items");
                    for (Map<String, Object> item : items) {
                        Map<String, Object> idObj = (Map<String, Object>) item.get("id");
                        Map<String, Object> snippet = (Map<String, Object>) item.get("snippet");
                        String videoId = (String) idObj.get("videoId");
                        String title = (String) snippet.get("title");
                        String channelTitle = (String) snippet.get("channelTitle");
                        
                        responseList.add(Map.of(
                                "id", videoId,
                                "title", title != null ? title : topic,
                                "thumbnailUrl", "https://img.youtube.com/vi/" + videoId + "/maxresdefault.jpg",
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
            System.err.println("SearchController YouTube API Exception:");
            e.printStackTrace();
            // Silently fallback to empty list
        }
        
        return ResponseEntity.ok(responseList);
    }
}

