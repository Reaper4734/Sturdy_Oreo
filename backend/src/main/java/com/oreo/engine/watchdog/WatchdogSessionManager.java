package com.oreo.engine.watchdog;

import org.springframework.stereotype.Component;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class WatchdogSessionManager {

    // Map of Session ID -> Last Heartbeat Timestamp
    private final Map<String, Instant> activeSessions = new ConcurrentHashMap<>();

    public void registerHeartbeat(String sessionId) {
        activeSessions.put(sessionId, Instant.now());
    }

    public void removeSession(String sessionId) {
        activeSessions.remove(sessionId);
    }

    public Map<String, Instant> getActiveSessions() {
        return activeSessions;
    }
}
