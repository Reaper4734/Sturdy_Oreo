package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;

@Data
public class WorkspaceChatOutputSchema {
    @JsonProperty("aiResponse")
    public String aiResponse;

    @JsonProperty("updatedRoadmap")
    public List<RoadmapNodeDto> updatedRoadmap;

    @Data
    public static class RoadmapNodeDto {
        @JsonProperty("id")
        public String id;
        @JsonProperty("title")
        public String title;
        @JsonProperty("description")
        public String description;
        @JsonProperty("activityType")
        public String activityType;
        @JsonProperty("status")
        public String status;
        @JsonProperty("children")
        public List<RoadmapNodeDto> children;
    }
}

