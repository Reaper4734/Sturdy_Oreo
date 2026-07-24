package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.YouTubeTranscriptService;
import com.oreo.engine.orchestration.model.Flashcard;
import com.oreo.engine.orchestration.repository.FlashcardRepository;
import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import dev.langchain4j.model.StreamingResponseHandler;
import dev.langchain4j.data.message.AiMessage;
import dev.langchain4j.model.output.Response;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@Service
public class StreamingOrchestrationService {

    private final StreamingChatLanguageModel streamingChatModel;
    private final SimpMessagingTemplate messagingTemplate;
    private final YouTubeTranscriptService youTubeTranscriptService;
    private final FlashcardGeneratorPipeline flashcardGeneratorPipeline;
    private final FlashcardRepository flashcardRepository;
    private final com.oreo.engine.orchestration.repository.ChatMessageRepository chatMessageRepository;
    private final com.oreo.engine.orchestration.repository.ChatThreadRepository chatThreadRepository;

    public StreamingOrchestrationService(
            StreamingChatLanguageModel streamingChatModel,
            SimpMessagingTemplate messagingTemplate,
            YouTubeTranscriptService youTubeTranscriptService,
            FlashcardGeneratorPipeline flashcardGeneratorPipeline,
            FlashcardRepository flashcardRepository,
            com.oreo.engine.orchestration.repository.ChatMessageRepository chatMessageRepository,
            com.oreo.engine.orchestration.repository.ChatThreadRepository chatThreadRepository) {
        this.streamingChatModel = streamingChatModel;
        this.messagingTemplate = messagingTemplate;
        this.youTubeTranscriptService = youTubeTranscriptService;
        this.flashcardGeneratorPipeline = flashcardGeneratorPipeline;
        this.flashcardRepository = flashcardRepository;
        this.chatMessageRepository = chatMessageRepository;
        this.chatThreadRepository = chatThreadRepository;
    }

    public void streamInterview(String sessionId, String userMessage) {
        streamingChatModel.generate(
                userMessage,
                new StreamingResponseHandler<AiMessage>() {
                    @Override
                    public void onNext(String token) {
                        messagingTemplate.convertAndSend("/topic/interview/" + sessionId, Map.of("token", token));
                    }

                    @Override
                    public void onComplete(Response<AiMessage> response) {
                        messagingTemplate.convertAndSend("/topic/interview/" + sessionId, Map.of("done", true));
                    }

                    @Override
                    public void onError(Throwable error) {
                        messagingTemplate.convertAndSend("/topic/interview/" + sessionId, Map.of("error", error.getMessage()));
                    }
                }
        );
    }

    public void streamCanvasExplanation(String sessionId, String userMessageText, String videoId, String timestampStr, String userIdStr) {
        UUID threadId;
        try {
            threadId = UUID.fromString(sessionId);
        } catch (Exception e) {
            threadId = UUID.nameUUIDFromBytes(sessionId.getBytes()); // Safe fallback for non-UUID strings
        }

        // Validate Ownership
        UUID requestUserId = UUID.fromString(userIdStr);
        com.oreo.engine.orchestration.model.ChatThread thread = chatThreadRepository.findById(threadId).orElse(null);
        if (thread != null && !thread.getUserId().equals(requestUserId)) {
            messagingTemplate.convertAndSend("/topic/canvas/" + sessionId, Map.of("error", "Unauthorized: Thread belongs to another user."));
            return;
        }

        String transcript = "No contextual video transcript available.";
        if (videoId != null && timestampStr != null) {
            try {
                int timestamp = Integer.parseInt(timestampStr);
                transcript = youTubeTranscriptService.getTranscriptBufferBeforeTimestamp(videoId, timestamp, 1000).orElse(transcript);
            } catch (NumberFormatException e) {
                // Ignore parse errors
            }
        }

        String systemPrompt = "You are an AI Tutor attached to an interactive whiteboard (Canvas). " +
                "The user is watching a video. Here is what the video was saying when they paused it: " + transcript + " " +
                "Explain their doubt clearly and mention what you would draw on the board.";

        // Build the Prompt Array
        List<dev.langchain4j.data.message.ChatMessage> promptArray = new ArrayList<>();
        promptArray.add(new dev.langchain4j.data.message.SystemMessage(systemPrompt));

        // Fetch last 10 historical messages from DB
        List<com.oreo.engine.orchestration.model.ChatMessageEntity> history = chatMessageRepository.findByThreadIdOrderByCreatedAtAsc(threadId);
        int startIndex = Math.max(0, history.size() - 10);
        for (int i = startIndex; i < history.size(); i++) {
            var entity = history.get(i);
            if ("USER".equals(entity.getRole())) {
                promptArray.add(new dev.langchain4j.data.message.UserMessage(entity.getContent()));
            } else if ("AI".equals(entity.getRole())) {
                promptArray.add(new dev.langchain4j.data.message.AiMessage(entity.getContent()));
            }
        }

        // Add the new user message
        promptArray.add(new dev.langchain4j.data.message.UserMessage(userMessageText));

        StringBuilder aiResponseBuilder = new StringBuilder();
        
        final UUID finalThreadId = threadId;

        streamingChatModel.generate(
                promptArray,
                new StreamingResponseHandler<AiMessage>() {
                    @Override
                    public void onNext(String token) {
                        aiResponseBuilder.append(token);
                        messagingTemplate.convertAndSend("/topic/canvas/" + sessionId, Map.of("token", token));
                    }

                    @Override
                    public void onComplete(Response<AiMessage> response) {
                        messagingTemplate.convertAndSend("/topic/canvas/" + sessionId, Map.of("done", true));
                        
                        // Save User Message to DB
                        com.oreo.engine.orchestration.model.ChatMessageEntity userEntity = new com.oreo.engine.orchestration.model.ChatMessageEntity();
                        userEntity.setThreadId(finalThreadId);
                        userEntity.setRole("USER");
                        userEntity.setContent(userMessageText);
                        chatMessageRepository.save(userEntity);

                        // Save AI Message to DB
                        com.oreo.engine.orchestration.model.ChatMessageEntity aiEntity = new com.oreo.engine.orchestration.model.ChatMessageEntity();
                        aiEntity.setThreadId(finalThreadId);
                        aiEntity.setRole("AI");
                        aiEntity.setContent(aiResponseBuilder.toString());
                        chatMessageRepository.save(aiEntity);
                    }

                    @Override
                    public void onError(Throwable error) {
                        messagingTemplate.convertAndSend("/topic/canvas/" + sessionId, Map.of("error", error.getMessage()));
                    }
                }
        );
    }

}
