package com.oreo.engine.watchdog;

import dev.langchain4j.model.chat.ChatLanguageModel;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WatchdogDaemonTest {

    @Mock
    private ChatLanguageModel chatLanguageModel;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    private WatchdogDaemon watchdogDaemon;

    @BeforeEach
    void setUp() {
        watchdogDaemon = new WatchdogDaemon(chatLanguageModel, messagingTemplate);
    }

    @Test
    void scanForIdleSessions_ShouldNotNudge_WhenSessionIsActive() {
        String sessionId = "active-session-123";
        watchdogDaemon.registerHeartbeat(sessionId);

        watchdogDaemon.scanForIdleSessions();

        verify(messagingTemplate, never()).convertAndSend(anyString(), any(Object.class));
    }

    @Test
    void removeSession_ShouldUnregisterSession() {
        String sessionId = "session-to-remove";
        watchdogDaemon.registerHeartbeat(sessionId);
        watchdogDaemon.removeSession(sessionId);

        assertDoesNotThrow(() -> watchdogDaemon.scanForIdleSessions());
        verify(messagingTemplate, never()).convertAndSend(anyString(), any(Object.class));
    }
}
