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
    private final com.oreo.engine.orchestration.pipelines.FlashcardGeneratorPipeline flashcardGeneratorPipeline;
    private final com.oreo.engine.orchestration.repository.FlashcardRepository flashcardRepository;

    public OrchestrationWebSocketController(StreamingChatLanguageModel streamingChatModel, 
                                            SimpMessagingTemplate messagingTemplate,
                                            WatchdogSessionManager watchdogSessionManager,
                                            YouTubeTranscriptService youTubeTranscriptService,
                                            com.oreo.engine.orchestration.pipelines.FlashcardGeneratorPipeline flashcardGeneratorPipeline,
                                            com.oreo.engine.orchestration.repository.FlashcardRepository flashcardRepository) {
        this.streamingChatModel = streamingChatModel;
        this.messagingTemplate = messagingTemplate;
        this.watchdogSessionManager = watchdogSessionManager;
        this.youTubeTranscriptService = youTubeTranscriptService;
        this.flashcardGeneratorPipeline = flashcardGeneratorPipeline;
        this.flashcardRepository = flashcardRepository;
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
                        
                        // Async flashcard extraction based on what was just explained
                        java.util.concurrent.CompletableFuture.runAsync(() -> {
                            try {
                                String fullResponse = response.content().text();
                                String combinedTranscript = "Q: " + userMessage + "\nA: " + fullResponse;
                                
                                java.util.List<com.oreo.engine.orchestration.pipelines.FlashcardGeneratorPipeline.ExtractedCard> cards = 
                                        flashcardGeneratorPipeline.generateFlashcards(combinedTranscript);
                                
                                // Save to DB
                                for (var extracted : cards) {
                                    com.oreo.engine.orchestration.model.Flashcard card = new com.oreo.engine.orchestration.model.Flashcard();
                                    // Mock UUID for user for now in this MVP
                                    card.setUserId(java.util.UUID.fromString("00000000-0000-0000-0000-000000000000"));
                                    card.setFront(extracted.frontQuestion);
                                    card.setBack(extracted.backAnswer);
                                    card.setNextReviewDate(java.time.LocalDate.now().plusDays(1));
                                    card.setIntervalDays(1);
                                    flashcardRepository.save(card);
                                }
                            } catch (Exception e) {
                                // Ignore flashcard generation errors so it doesn't crash WS
                            }
                        });
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
