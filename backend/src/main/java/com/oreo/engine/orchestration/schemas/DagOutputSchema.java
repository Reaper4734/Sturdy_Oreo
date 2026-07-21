package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

@Data
public class DagOutputSchema {

    @JsonProperty("track_id")
    private String trackId;

    @JsonProperty("goal")
    private String goal;

    @JsonProperty("nodes")
    private List<DagNode> nodes;

    @Data
    public static class DagNode {
        @JsonProperty("id")
        private String id;

        @JsonProperty("title")
        private String title;

        @JsonProperty("type")
        private String type;

        @JsonProperty("prereqs")
        private List<String> prereqs;

        @JsonProperty("rationale")
        private String rationale;

        @JsonProperty("alternatives")
        private List<String> alternatives;
    }
}
