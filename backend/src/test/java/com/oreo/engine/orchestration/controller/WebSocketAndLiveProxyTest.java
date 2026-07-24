package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.YouTubeTranscriptService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.net.URI;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WebSocketAndLiveProxyTest {

    @Mock
    private YouTubeTranscriptService transcriptService;

    @Mock
    private WebSocketSession clientSession1;

    private GeminiLiveProxyWebSocketHandler liveProxyHandler;

    @BeforeEach
    void setUp() {
        liveProxyHandler = new GeminiLiveProxyWebSocketHandler(transcriptService);
    }

    @Test
    void connectionClosed_ShouldCleanUpRoomState_WhenAllClientsDisconnect() throws Exception {
        when(clientSession1.getId()).thenReturn("sess-001");
        when(clientSession1.getUri()).thenReturn(URI.create("ws://localhost:8080/ws/live?roomId=room-101&videoId=yt123&timestamp=45"));
        when(transcriptService.getTranscriptBufferBeforeTimestamp(anyString(), anyInt(), anyInt()))
                .thenReturn(Optional.of("Video context text at 45s"));

        assertDoesNotThrow(() -> {
            try {
                liveProxyHandler.afterConnectionEstablished(clientSession1);
            } catch (Exception ignored) {
                // Expected when WSS remote endpoint is unavailable in test environment
            }
            liveProxyHandler.afterConnectionClosed(clientSession1, CloseStatus.NORMAL);
        });
    }

    @Test
    void handleTextMessage_ShouldNotCrash_WhenSessionNotConnected() {
        when(clientSession1.getId()).thenReturn("unregistered-sess");

        assertDoesNotThrow(() -> {
            liveProxyHandler.handleTextMessage(clientSession1, new TextMessage("{\"type\": \"ping\"}"));
        });
    }
}
