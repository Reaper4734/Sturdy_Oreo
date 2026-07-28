package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class AssessmentEvaluationSchema {

    @JsonProperty("isPassed")
    private boolean isPassed;

    @JsonProperty("score")
    private int score; // 0-100

    @JsonProperty("feedback")
    private String feedback;

    @JsonProperty("suggestedReviewTopic")
    private String suggestedReviewTopic;
}
