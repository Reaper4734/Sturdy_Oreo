package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class KnowledgeGraphSchema {

    @JsonProperty("courseTitle")
    private String courseTitle;

    @JsonProperty("version")
    private Integer version;

    @JsonProperty("graphType")
    private String graphType = "DAG";

    @JsonProperty("difficulty")
    private String difficulty;

    @JsonProperty("estimatedHours")
    private Integer estimatedHours;

    @JsonProperty("generatedAt")
    private String generatedAt;

    @JsonProperty("nodes")
    private List<KnowledgeNode> nodes;

    @JsonProperty("edges")
    private List<GraphEdge> edges;

    @Data
    public static class KnowledgeNode {
        @JsonProperty("id")
        private String id;

        @JsonProperty("title")
        private String title;

        @JsonProperty("type")
        private NodeType type;

        @JsonProperty("estimatedHours")
        private Integer estimatedHours;

        @JsonProperty("difficulty")
        private String difficulty;

        @JsonProperty("tags")
        private List<String> tags;

        @JsonProperty("rationale")
        private String rationale;
        
        @JsonProperty("alternatives")
        private List<String> alternatives;
    }
}
