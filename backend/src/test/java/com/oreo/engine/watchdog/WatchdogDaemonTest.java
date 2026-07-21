package com.oreo.engine.watchdog;

import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import com.oreo.engine.orchestration.pipelines.SmartNudgePipeline;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.Instant;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WatchdogDaemonTest {

    @Mock
    private SmartNudgePipeline smartNudgePipeline;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    private WatchdogSessionManager sessionManager;
    private WatchdogDaemon watchdogDaemon;

    @BeforeEach
    void setUp() {
        sessionManager = new WatchdogSessionManager();
        watchdogDaemon = new WatchdogDaemon(sessionManager, smartNudgePipeline, messagingTemplate);
    }

    @Test
    void scanForIdleSessions_ShouldNotNudge_WhenSessionIsActive() {
        // Arrange
        String sessionId = "active-session-123";
        sessionManager.registerHeartbeat(sessionId);

        // Act
        watchdogDaemon.scanForIdleSessions();

        // Assert
        verify(smartNudgePipeline, never()).run(any(OrchestrationRequest.class));
        verify(messagingTemplate, never()).convertAndSend(anyString(), any(Object.class));
    }

    @Test
    void scanForIdleSessions_ShouldTriggerNudge_WhenSessionIsIdle() throws InterruptedException {
        // Arrange
        String sessionId = "idle-session-999";
        // Force the heartbeat to be 4 minutes ago (240 seconds > 180 seconds threshold)
        sessionManager.getActiveSessions().put(sessionId, Instant.now().minusSeconds(240));

        OrchestrationResponse mockResponse = OrchestrationResponse.builder()
                .payload(Map.of("intervention_type", "nudge", "message", "Wake up!"))
                .build();

        when(smartNudgePipeline.run(any(OrchestrationRequest.class))).thenReturn(mockResponse);

        // Act
        watchdogDaemon.scanForIdleSessions();

        // Assert
        verify(smartNudgePipeline, times(1)).run(any(OrchestrationRequest.class));
        
        @SuppressWarnings("unchecked")
        ArgumentCaptor<Map<String, Object>> payloadCaptor = ArgumentCaptor.forClass(Map.class);
        
        verify(messagingTemplate, times(1)).convertAndSend(
                eq("/topic/session/idle-session-999/interventions"), 
                payloadCaptor.capture()
        );

        Map<String, Object> sentPayload = payloadCaptor.getValue();
        assertEquals("nudge", sentPayload.get("intervention_type"));
        assertEquals("Wake up!", sentPayload.get("message"));

        // Verify the heartbeat was reset so we don't spam them continuously
        Instant updatedHeartbeat = sessionManager.getActiveSessions().get(sessionId);
        assertTrue(updatedHeartbeat.isAfter(Instant.now().minusSeconds(5)));
    }
}
