package com.oreo.engine.orchestration.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrchestrationResponse {
    private String replyToUser; // For chat
    private java.util.List<String> options; // Dynamic action chips/buttons
    private Map<String, Object> internalState; // Extracted persona, confidence, etc.
    private Object payload; // e.g., DAG output, Canvas payload, Quiz output
}
