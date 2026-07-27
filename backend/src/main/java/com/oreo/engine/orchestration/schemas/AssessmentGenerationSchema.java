package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;

@Data
public class AssessmentGenerationSchema {

    @JsonProperty("questions")
    private List<QuestionSchema> questions;

    @Data
    public static class QuestionSchema {
        @JsonProperty("id")
        private String id;

        @JsonProperty("topicTag")
        private String topicTag;

        @JsonProperty("questionText")
        private String questionText;

        @JsonProperty("type")
        private String type; // "mcq" or "subjective"

        @JsonProperty("options")
        private List<OptionSchema> options; // empty for subjective
    }

    @Data
    public static class OptionSchema {
        @JsonProperty("id")
        private String id;

        @JsonProperty("text")
        private String text;

        @JsonProperty("isCorrect")
        private boolean isCorrect;

        @JsonProperty("explanation")
        private String explanation;
    }
}
