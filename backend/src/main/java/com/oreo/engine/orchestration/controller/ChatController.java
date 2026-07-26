package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.model.ChatThread;
import com.oreo.engine.orchestration.model.ChatMessageEntity;
import com.oreo.engine.orchestration.repository.ChatThreadRepository;
import com.oreo.engine.orchestration.repository.ChatMessageRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/orchestration/chats")
public class ChatController {

    private final ChatThreadRepository chatThreadRepository;
    private final ChatMessageRepository chatMessageRepository;

    public ChatController(ChatThreadRepository chatThreadRepository, ChatMessageRepository chatMessageRepository) {
        this.chatThreadRepository = chatThreadRepository;
        this.chatMessageRepository = chatMessageRepository;
    }

    @GetMapping
    public ResponseEntity<List<ChatThread>> getChats(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(chatThreadRepository.findByUserIdOrderByCreatedAtDesc(userId));
    }

    @PostMapping
    public ResponseEntity<ChatThread> createChat(@RequestBody Map<String, String> payload, Authentication authentication) {
        ChatThread thread = new ChatThread();
        thread.setUserId((UUID) authentication.getPrincipal());
        thread.setVideoId(payload.get("videoId"));
        thread.setTopic(payload.get("topic"));
        thread.setTitle(payload.getOrDefault("title", "New Conversation"));
        return ResponseEntity.ok(chatThreadRepository.save(thread));
    }

    @GetMapping("/{threadId}/messages")
    public ResponseEntity<List<ChatMessageEntity>> getMessages(@PathVariable UUID threadId) {
        return ResponseEntity.ok(chatMessageRepository.findByThreadIdOrderByCreatedAtAsc(threadId));
    }
}
