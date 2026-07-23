package com.oreo.engine.watchdog;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class WatchdogDaemon {

    private static final Logger log = LoggerFactory.getLogger(WatchdogDaemon.class);
    
    // Inactivity threshold before nudging (e.g., 3 minutes)
    private static final long INACTIVITY_THRESHOLD_SECONDS = 180; 

    // Map of Session ID -> Last Heartbeat Timestamp
    private final Map<String, Instant> activeSessions = new ConcurrentHashMap<>();

    private final NudgeAgent nudgeAgent;
    private final SimpMessagingTemplate messagingTemplate;

    interface NudgeAgent {
        @SystemMessage({
                "You are an AI learning coach.",
                "The student has been idle for several minutes.",
                "Generate a short, engaging, 1-sentence nudge to get their attention back to the canvas.",
                "Do not be aggressive. Be encouraging or mildly playful."
        })
        String generateNudge(@UserMessage String context);
    }

    public WatchdogDaemon(ChatLanguageModel chatLanguageModel, 
                          SimpMessagingTemplate messagingTemplate) {
        this.nudgeAgent = AiServices.builder(NudgeAgent.class)
                .chatLanguageModel(chatLanguageModel)
                .build();
        this.messagingTemplate = messagingTemplate;
    }

    public void registerHeartbeat(String sessionId) {
        activeSessions.put(sessionId, Instant.now());
    }

    public void removeSession(String sessionId) {
        activeSessions.remove(sessionId);
    }

    // Run every 30 seconds
    @Scheduled(fixedRate = 30000)
    public void scanForIdleSessions() {
        Instant now = Instant.now();
        
        for (Map.Entry<String, Instant> entry : activeSessions.entrySet()) {
            String sessionId = entry.getKey();
            Instant lastHeartbeat = entry.getValue();
            
            long idleSeconds = Duration.between(lastHeartbeat, now).getSeconds();
            
            if (idleSeconds > INACTIVITY_THRESHOLD_SECONDS) {
                log.info("Session {} is idle for {} seconds. Triggering nudge intervention.", sessionId, idleSeconds);
                
                // 1. Generate Nudge
                String nudgeMessage = nudgeAgent.generateNudge("Student is idle. Current topic is unknown.");
                
                // 2. Push to WebSocket Topic
                messagingTemplate.convertAndSend("/topic/session/" + sessionId + "/interventions", Map.of("intervention_type", "nudge", "message", nudgeMessage));
                
                // 3. Reset heartbeat to avoid spamming the student
                registerHeartbeat(sessionId);
            }
        }
    }
}
