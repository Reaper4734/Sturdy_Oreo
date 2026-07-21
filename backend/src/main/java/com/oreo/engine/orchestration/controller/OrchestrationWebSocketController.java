package com.oreo.engine.orchestration.controller;

import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import com.oreo.engine.watchdog.WatchdogSessionManager;
import com.oreo.engine.orchestration.YouTubeTranscriptService;

import java.util.Map;

@Controller
public class OrchestrationWebSocketController {

    private final StreamingChatLanguageModel streamingChatModel;
    private final SimpMessagingTemplate messagingTemplate;
    private final WatchdogSessionManager watchdogSessionManager;
    private final YouTubeTranscriptService youTubeTranscriptService;

    public OrchestrationWebSocketController(StreamingChatLanguageModel streamingChatModel, 
                                            SimpMessagingTemplate messagingTemplate,
                                            WatchdogSessionManager watchdogSessionManager,
                                            YouTubeTranscriptService youTubeTranscriptService) {
        this.streamingChatModel = streamingChatModel;
        this.messagingTemplate = messagingTemplate;
        this.watchdogSessionManager = watchdogSessionManager;
        this.youTubeTranscriptService = youTubeTranscriptService;
    }

    @MessageMapping("/interview/stream")
    public void streamInterview(Map<String, String> payload) {
        String userMessage = payload.getOrDefault("message", "Hello");
        String sessionId = payload.getOrDefault("sessionId", "default");

        streamingChatModel.generate(
                userMessage,
                new dev.langchain4j.model.StreamingResponseHandler<dev.langchain4j.data.message.AiMessage>() {
                    @Override
                    public void onNext(String token) {
                        messagingTemplate.convertAndSend("/topic/interview/" + sessionId, Map.of("token", token));
                    }

                    @Override
                    public void onComplete(dev.langchain4j.model.output.Response<dev.langchain4j.data.message.AiMessage> response) {
                        messagingTemplate.convertAndSend("/topic/interview/" + sessionId, Map.of("done", true));
                    }

                    @Override
                    public void onError(Throwable error) {
                        messagingTemplate.convertAndSend("/topic/interview/" + sessionId, Map.of("error", error.getMessage()));
                    }
                }
        );
    }

    @MessageMapping("/canvas/stream")
    public void streamCanvasTutor(Map<String, String> payload) {
        String userMessage = payload.getOrDefault("message", "Can you explain this concept?");
        String sessionId = payload.getOrDefault("sessionId", "default");
        String videoId = payload.get("videoId");
        String timestampStr = payload.get("timestamp");

        // Fetch transcript if video data is provided
        String transcript = "No contextual video transcript available.";
        if (videoId != null && timestampStr != null) {
            try {
                int timestamp = Integer.parseInt(timestampStr);
                transcript = youTubeTranscriptService.getTranscriptAtTimestamp(videoId, timestamp).orElse(transcript);
            } catch (NumberFormatException e) {
                // Ignore parse errors
            }
        }

        // System context to ensure it behaves as a Canvas Tutor
        String systemPrompt = "You are an AI Tutor attached to an interactive whiteboard (Canvas). " +
                "The user is watching a video. Here is what the video was saying when they paused it: " + transcript + " " +
                "The user is asking a doubt. Explain it clearly and mention what you would draw on the board.";
                
        streamingChatModel.generate(
                systemPrompt + "\n\nUser Doubt: " + userMessage,
                new dev.langchain4j.model.StreamingResponseHandler<dev.langchain4j.data.message.AiMessage>() {
                    @Override
                    public void onNext(String token) {
                        messagingTemplate.convertAndSend("/topic/canvas/" + sessionId, Map.of("token", token));
                    }

                    @Override
                    public void onComplete(dev.langchain4j.model.output.Response<dev.langchain4j.data.message.AiMessage> response) {
                        messagingTemplate.convertAndSend("/topic/canvas/" + sessionId, Map.of("done", true));
                    }

                    @Override
                    public void onError(Throwable error) {
                        messagingTemplate.convertAndSend("/topic/canvas/" + sessionId, Map.of("error", error.getMessage()));
                    }
                }
        );
    }

    @MessageMapping("/session/heartbeat")
    public void receiveHeartbeat(Map<String, String> payload) {
        String sessionId = payload.getOrDefault("sessionId", "default");
        watchdogSessionManager.registerHeartbeat(sessionId);
    }
}
