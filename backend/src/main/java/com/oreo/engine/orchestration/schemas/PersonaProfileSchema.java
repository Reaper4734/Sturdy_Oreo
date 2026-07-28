package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;

@Data
public class PersonaProfileSchema {
    @JsonProperty("renderMode")
    private String renderMode = "default";
    
    @JsonProperty("title")
    private String title;
    
    @JsonProperty("subtitle")
    private String subtitle;
    
    @JsonProperty("summary")
    private String summary;
    
    @JsonProperty("traits")
    private List<String> traits;
    
    @JsonProperty("metrics")
    private CognitiveMetrics metrics;
    
    @JsonProperty("blueprintNodes")
    private List<BlueprintNode> blueprintNodes;

    @Data
    public static class CognitiveMetrics {
        @JsonProperty("visualization")
        private double visualization;
        @JsonProperty("applied")
        private double applied;
        @JsonProperty("theoretical")
        private double theoretical;
        @JsonProperty("pacing")
        private double pacing;
        @JsonProperty("logic")
        private double logic;
    }

    @Data
    public static class BlueprintNode {
        @JsonProperty("id")
        private String id;
        @JsonProperty("dayRange")
        private String dayRange;
        @JsonProperty("title")
        private String title;
        @JsonProperty("description")
        private String description;
        @JsonProperty("topics")
        private List<String> topics;
        @JsonProperty("alternatives")
        private List<String> alternatives;
        @JsonProperty("selectedFormat")
        private String selectedFormat = "Interactive Sandbox";
        @JsonProperty("isHandsOnFocus")
        private boolean isHandsOnFocus = true;
    }
}
