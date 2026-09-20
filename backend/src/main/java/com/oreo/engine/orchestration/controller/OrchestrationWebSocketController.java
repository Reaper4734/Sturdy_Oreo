package com.oreo.engine.orchestration.controller;


import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.stereotype.Controller;



import java.util.Map;

@Controller
public class OrchestrationWebSocketController {

    private final com.oreo.engine.orchestration.pipelines.StreamingOrchestrationService streamingService;

    public OrchestrationWebSocketController(com.oreo.engine.orchestration.pipelines.StreamingOrchestrationService streamingService) {
        this.streamingService = streamingService;
    }

    @MessageMapping("/interview/stream")
    public void streamInterview(Map<String, String> payload) {
        String userMessage = payload.getOrDefault("message", "Hello");
        String sessionId = payload.getOrDefault("sessionId", "default");

        streamingService.streamInterview(sessionId, userMessage);
    }

    @MessageMapping("/canvas/stream")
    public void streamCanvasTutor(Map<String, String> payload, java.security.Principal principal) {
        String sessionId = payload.getOrDefault("sessionId", "default");
        String userIdStr = (principal != null && principal.getName() != null && !principal.getName().isBlank()) 
                ? principal.getName() 
                : payload.getOrDefault("userId", "user_active");

        String userMessage = payload.getOrDefault("message", "Can you explain this concept?");
        String videoId = payload.get("videoId");
        String timestampStr = payload.get("timestamp");

        streamingService.streamCanvasExplanation(sessionId, userMessage, videoId, timestampStr, userIdStr);
    }
}
