package com.oreo.engine.orchestration.controller;

import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import com.oreo.engine.watchdog.WatchdogDaemon;
import com.oreo.engine.orchestration.YouTubeTranscriptService;

import java.util.Map;

@Controller
public class OrchestrationWebSocketController {

    private final com.oreo.engine.orchestration.pipelines.StreamingOrchestrationService streamingService;
    private final WatchdogDaemon watchdogDaemon;

    public OrchestrationWebSocketController(com.oreo.engine.orchestration.pipelines.StreamingOrchestrationService streamingService,
                                            WatchdogDaemon watchdogDaemon) {
        this.streamingService = streamingService;
        this.watchdogDaemon = watchdogDaemon;
    }

    @MessageMapping("/interview/stream")
    public void streamInterview(Map<String, String> payload) {
        String userMessage = payload.getOrDefault("message", "Hello");
        String sessionId = payload.getOrDefault("sessionId", "default");

        streamingService.streamInterview(sessionId, userMessage);
    }

    @MessageMapping("/canvas/stream")
    public void streamCanvasTutor(Map<String, String> payload, java.security.Principal principal) {
        if (principal == null) return;

        String userMessage = payload.getOrDefault("message", "Can you explain this concept?");
        String sessionId = payload.getOrDefault("sessionId", "default");
        String videoId = payload.get("videoId");
        String timestampStr = payload.get("timestamp");

        streamingService.streamCanvasExplanation(sessionId, userMessage, videoId, timestampStr, principal.getName());
    }

    @MessageMapping("/session/heartbeat")
    public void receiveHeartbeat(Map<String, String> payload) {
        String sessionId = payload.getOrDefault("sessionId", "default");
        watchdogDaemon.registerHeartbeat(sessionId);
    }
}
