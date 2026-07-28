package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;
import java.util.ArrayList;

@Data
public class MindMapSchema {

    @JsonProperty("subjectId")
    private String subjectId;

    @JsonProperty("subjectTitle")
    private String subjectTitle;

    @JsonProperty("rootNode")
    private ConceptNode rootNode;

    @Data
    public static class ConceptNode {
        @JsonProperty("id")
        private String id;

        @JsonProperty("label")
        private String label;

        @JsonProperty("depthLevel")
        private int depthLevel;

        @JsonProperty("isTerminal")
        private boolean isTerminal;

        @JsonProperty("children")
        private List<ConceptNode> children = new ArrayList<>();
    }
}
