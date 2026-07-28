package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;

@Data
public class FlashcardGenerationSchema {

    @JsonProperty("flashcards")
    private List<FlashcardSchema> flashcards;

    @Data
    public static class FlashcardSchema {
        @JsonProperty("id")
        private String id;

        @JsonProperty("frontHtml")
        private String frontHtml;

        @JsonProperty("backHtml")
        private String backHtml;
    }
}
