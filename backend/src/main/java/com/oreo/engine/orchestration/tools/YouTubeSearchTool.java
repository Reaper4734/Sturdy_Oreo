package com.oreo.engine.orchestration.tools;

import dev.langchain4j.agent.tool.Tool;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Component
public class YouTubeSearchTool {

    @Value("${youtube.api.key:NONE}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();

    @Tool("Searches YouTube for real educational videos on a given topic and returns the top 3 results with URLs.")
    public String searchEducationalVideos(String topic) {
        if ("NONE".equals(apiKey)) {
            return "Error: YouTube API Key is missing. Return mock URLs like https://youtube.com/watch?v=mock123 for now.";
        }

        int maxRetries = 3;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                String url = String.format("https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=3&q=%s&type=video&key=%s", topic, apiKey);
                Map<String, Object> response = restTemplate.getForObject(url, Map.class);

                if (response == null || !response.containsKey("items")) {
                    return "No videos found.";
                }

                List<Map<String, Object>> items = (List<Map<String, Object>>) response.get("items");
                return items.stream().map(item -> {
                    Map<String, Object> id = (Map<String, Object>) item.get("id");
                    Map<String, Object> snippet = (Map<String, Object>) item.get("snippet");
                    String videoId = (String) id.get("videoId");
                    String title = (String) snippet.get("title");
                    return String.format("Title: %s, URL: https://youtube.com/watch?v=%s", title, videoId);
                }).collect(Collectors.joining("\n"));

            } catch (Exception e) {
                if (attempt == maxRetries) {
                    return "Title: Search for " + topic + " on YouTube, URL: https://www.youtube.com/results?search_query=" + topic.replace(" ", "+");
                }
                // Wait briefly before retrying
                try { Thread.sleep(500); } catch (InterruptedException ignored) {}
            }
        }
        return "No videos found.";
    }
}
