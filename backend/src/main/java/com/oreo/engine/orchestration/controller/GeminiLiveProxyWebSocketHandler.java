package com.oreo.engine.orchestration.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.handler.AbstractWebSocketHandler;

import java.net.URI;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class GeminiLiveProxyWebSocketHandler extends AbstractWebSocketHandler {

    @Value("${oreo.llm.gemini-api-key:dummy-gemini-key}")
    private String apiKey;

    // Maps roomId to the shared Google Gemini Live session
    private final Map<String, WebSocketSession> roomGeminiSessions = new ConcurrentHashMap<>();
    
    // Maps roomId to the list of connected student client sessions
    private final Map<String, java.util.List<WebSocketSession>> roomClients = new ConcurrentHashMap<>();
    
    // Helper to find the roomId for a given client
    private final Map<String, String> clientToRoomMap = new ConcurrentHashMap<>();

    private final com.oreo.engine.orchestration.YouTubeTranscriptService youTubeTranscriptService;

    public GeminiLiveProxyWebSocketHandler(com.oreo.engine.orchestration.YouTubeTranscriptService youTubeTranscriptService) {
        this.youTubeTranscriptService = youTubeTranscriptService;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession clientSession) throws Exception {
        String query = clientSession.getUri().getQuery();
        String roomId = "default-room";
        String videoId = null;
        int timestamp = 0;
        
        if (query != null) {
            for (String param : query.split("&")) {
                if (param.startsWith("roomId=")) roomId = param.split("=")[1];
                if (param.startsWith("videoId=")) videoId = param.split("=")[1];
                if (param.startsWith("timestamp=")) timestamp = Integer.parseInt(param.split("=")[1]);
            }
        }
        
        clientToRoomMap.put(clientSession.getId(), roomId);
        roomClients.computeIfAbsent(roomId, k -> new java.util.concurrent.CopyOnWriteArrayList<>()).add(clientSession);

        // If this is the first student in the room, start the Gemini session
        if (!roomGeminiSessions.containsKey(roomId)) {
            String geminiWsUrl = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=" + apiKey;
            
            final String finalRoomId = roomId;
            StandardWebSocketClient webSocketClient = new StandardWebSocketClient();
            WebSocketSession geminiSession = webSocketClient.execute(new AbstractWebSocketHandler() {
                @Override
                protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
                    // Broadcast to all students in the room
                    for (WebSocketSession s : roomClients.getOrDefault(finalRoomId, java.util.Collections.emptyList())) {
                        if (s.isOpen()) s.sendMessage(message);
                    }
                }

                @Override
                protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) throws Exception {
                    // Broadcast audio to all students in the room
                    for (WebSocketSession s : roomClients.getOrDefault(finalRoomId, java.util.Collections.emptyList())) {
                        if (s.isOpen()) s.sendMessage(message);
                    }
                }

                @Override
                public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
                    roomGeminiSessions.remove(finalRoomId);
                }
            }, geminiWsUrl).get();

            roomGeminiSessions.put(roomId, geminiSession);
            
            // Fetch Context
            String transcriptContext = "No contextual video transcript available.";
            if (videoId != null) {
                transcriptContext = youTubeTranscriptService.getTranscriptBufferBeforeTimestamp(videoId, timestamp, 1000).orElse(transcriptContext);
            }
            // Escape quotes to prevent JSON injection
            transcriptContext = transcriptContext.replace("\"", "\\\"").replace("\n", " ");

            // Send initial setup frame telling Gemini we want Audio Out with system context
            String systemInstructionText = "You are a voice tutor. The user is struggling to understand a concept. They paused the video here. Context: " + transcriptContext + " Answer concisely using voice.";
            String setupJson = "{" +
                "\"setup\": {" +
                    "\"model\": \"models/gemini-2.5-flash\"," +
                    "\"generationConfig\": {\"responseModalities\": [\"AUDIO\"]}," +
                    "\"systemInstruction\": {" +
                        "\"parts\": [{\"text\": \"" + systemInstructionText + "\"}]" +
                    "}" +
                "}" +
            "}";
            
            geminiSession.sendMessage(new TextMessage(setupJson));
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession clientSession, TextMessage message) throws Exception {
        String roomId = clientToRoomMap.get(clientSession.getId());
        if (roomId != null) {
            WebSocketSession geminiSession = roomGeminiSessions.get(roomId);
            if (geminiSession != null && geminiSession.isOpen()) {
                geminiSession.sendMessage(message);
            }
        }
    }

    @Override
    protected void handleBinaryMessage(WebSocketSession clientSession, BinaryMessage message) throws Exception {
        // NOTE: In a true production environment, binary audio from multiple clients needs to be mixed before sending to Gemini.
        // For this MVP, we forward raw packets. The Flutter client should handle push-to-talk to prevent collision.
        String roomId = clientToRoomMap.get(clientSession.getId());
        if (roomId != null) {
            WebSocketSession geminiSession = roomGeminiSessions.get(roomId);
            if (geminiSession != null && geminiSession.isOpen()) {
                geminiSession.sendMessage(message);
            }
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession clientSession, CloseStatus status) throws Exception {
        String roomId = clientToRoomMap.remove(clientSession.getId());
        if (roomId != null) {
            java.util.List<WebSocketSession> clients = roomClients.get(roomId);
            if (clients != null) {
                clients.remove(clientSession);
                // If room is empty, close the Gemini connection
                if (clients.isEmpty()) {
                    WebSocketSession geminiSession = roomGeminiSessions.remove(roomId);
                    if (geminiSession != null && geminiSession.isOpen()) {
                        geminiSession.close(status);
                    }
                    roomClients.remove(roomId);
                }
            }
        }
    }
}
