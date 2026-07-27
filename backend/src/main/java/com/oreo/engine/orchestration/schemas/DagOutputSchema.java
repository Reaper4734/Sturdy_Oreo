package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

@Data
public class DagOutputSchema {

    @JsonProperty("track_id")
    private String trackId;

    @JsonProperty("courseTitle")
    private String courseTitle;

    @JsonProperty("version")
    private Integer version;

    @JsonProperty("graphType")
    private String graphType;

    @JsonProperty("difficulty")
    private String difficulty;

    @JsonProperty("estimatedHours")
    private Integer estimatedHours;

    @JsonProperty("goal")
    private String goal;

    @JsonProperty("nodes")
    private List<DagNode> nodes;

    @Data
    public static class DagNode {
        @dev.langchain4j.model.output.structured.Description("Deterministic ID (e.g. python_basics). No spaces or UUIDs.")
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

        @dev.langchain4j.model.output.structured.Description("List of prerequisite Node IDs required before this node unlocks.")
        @JsonProperty("prereqs")
        private List<String> prereqs;

        @JsonProperty("rationale")
        private String rationale;

        @JsonProperty("alternatives")
        private List<String> alternatives;
    }
}
