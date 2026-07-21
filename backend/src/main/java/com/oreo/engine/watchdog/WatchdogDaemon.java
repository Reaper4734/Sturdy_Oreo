package com.oreo.engine.watchdog;

import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import com.oreo.engine.orchestration.pipelines.SmartNudgePipeline;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;

@Component
public class WatchdogDaemon {

    private static final Logger log = LoggerFactory.getLogger(WatchdogDaemon.class);
    
    // Inactivity threshold before nudging (e.g., 3 minutes)
    private static final long INACTIVITY_THRESHOLD_SECONDS = 180; 

    private final WatchdogSessionManager sessionManager;
    private final SmartNudgePipeline smartNudgePipeline;
    private final SimpMessagingTemplate messagingTemplate;

    public WatchdogDaemon(WatchdogSessionManager sessionManager, 
                          SmartNudgePipeline smartNudgePipeline, 
                          SimpMessagingTemplate messagingTemplate) {
        this.sessionManager = sessionManager;
        this.smartNudgePipeline = smartNudgePipeline;
        this.messagingTemplate = messagingTemplate;
    }

    // Run every 30 seconds
    @Scheduled(fixedRate = 30000)
    public void scanForIdleSessions() {
        Instant now = Instant.now();
        
        for (Map.Entry<String, Instant> entry : sessionManager.getActiveSessions().entrySet()) {
            String sessionId = entry.getKey();
            Instant lastHeartbeat = entry.getValue();
            
            long idleSeconds = Duration.between(lastHeartbeat, now).getSeconds();
            
            if (idleSeconds > INACTIVITY_THRESHOLD_SECONDS) {
                log.info("Session {} is idle for {} seconds. Triggering nudge intervention.", sessionId, idleSeconds);
                
                // 1. Generate Nudge
                OrchestrationRequest req = new OrchestrationRequest();
                OrchestrationResponse nudgeResponse = smartNudgePipeline.run(req);
                
                // 2. Push to WebSocket Topic
                messagingTemplate.convertAndSend("/topic/session/" + sessionId + "/interventions", nudgeResponse.getPayload());
                
                // 3. Reset heartbeat to avoid spamming the student
                sessionManager.registerHeartbeat(sessionId);
            }
        }
    }
}
