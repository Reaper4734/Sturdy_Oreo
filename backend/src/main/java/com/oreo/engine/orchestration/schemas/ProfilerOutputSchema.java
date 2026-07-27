package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class ProfilerOutputSchema {

    @JsonProperty("reply_to_user")
    private String replyToUser;
    
    @dev.langchain4j.model.output.structured.Description("List of short interactive reply options (max 2-3) for the user to select from. CRITICAL: MUST include an option ending with '➔' (e.g., 'Generate Curriculum ➔') if confidence_score >= 80.")
    @JsonProperty("options")
    private java.util.List<String> options;

    @JsonProperty("internal_state")
    private InternalState internalState;

    @Data
    public static class InternalState {
        @JsonProperty("domain_identified")
        private boolean domainIdentified;

        @JsonProperty("eq_identified")
        private boolean eqIdentified;

        @JsonProperty("modality_identified")
        private boolean modalityIdentified;

        @JsonProperty("confidence_score")
        private int confidenceScore;

        @JsonProperty("current_inferred_persona")
        private InferredPersona currentInferredPersona;
    }

    @Data
    public static class InferredPersona {
        @JsonProperty("domain")
        private String domain;

        @JsonProperty("iq_logic")
        private String iqLogic;

        @JsonProperty("eq_resilience")
        private String eqResilience;
    }
}
