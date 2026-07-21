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

    @Value("${oreo.llm.gemini-api-key:AQ.Ab8RN6J7qoU7rqdkBofZ2GPqE1lGfzWbqUzrIf7KVcAU77ENwQ}")
    private String apiKey;

    // Maps the frontend client session to the Google Gemini Live session
    private final Map<String, WebSocketSession> geminiSessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession clientSession) throws Exception {
        String geminiWsUrl = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=" + apiKey;
        
        StandardWebSocketClient webSocketClient = new StandardWebSocketClient();
        WebSocketSession geminiSession = webSocketClient.execute(new AbstractWebSocketHandler() {
            @Override
            protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
                // Forward JSON responses from Gemini down to the Flutter client
                if (clientSession.isOpen()) {
                    clientSession.sendMessage(message);
                }
            }

            @Override
            protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) throws Exception {
                // Forward binary audio streams from Gemini down to the Flutter client
                if (clientSession.isOpen()) {
                    clientSession.sendMessage(message);
                }
            }

            @Override
            public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
                if (clientSession.isOpen()) {
                    clientSession.close(status);
                }
            }
        }, geminiWsUrl).get();

        geminiSessions.put(clientSession.getId(), geminiSession);
        
        // Send initial setup frame telling Gemini we want Audio Out
        String setupJson = "{\"setup\": {\"model\": \"models/gemini-2.5-flash\", \"generationConfig\": {\"responseModalities\": [\"AUDIO\"]}}}";
        geminiSession.sendMessage(new TextMessage(setupJson));
    }

    @Override
    protected void handleTextMessage(WebSocketSession clientSession, TextMessage message) throws Exception {
        WebSocketSession geminiSession = geminiSessions.get(clientSession.getId());
        if (geminiSession != null && geminiSession.isOpen()) {
            geminiSession.sendMessage(message);
        }
    }

    @Override
    protected void handleBinaryMessage(WebSocketSession clientSession, BinaryMessage message) throws Exception {
        // This receives raw PCM audio from Flutter and pushes it to Gemini
        WebSocketSession geminiSession = geminiSessions.get(clientSession.getId());
        if (geminiSession != null && geminiSession.isOpen()) {
            geminiSession.sendMessage(message);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession clientSession, CloseStatus status) throws Exception {
        WebSocketSession geminiSession = geminiSessions.remove(clientSession.getId());
        if (geminiSession != null && geminiSession.isOpen()) {
            geminiSession.close(status);
        }
    }
}
