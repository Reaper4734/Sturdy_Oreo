package com.oreo.engine.orchestration.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrchestrationRequest {
    private UUID userId;
    private OrchestrationMode mode;
    private String userInput; // The latest message or action from the student
    private Map<String, Object> context; // Additional context (e.g. current node id, video timestamp, persona)
    
    @Builder.Default
    private Map<String, String> contextualData = new HashMap<>();
}
