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

        @JsonProperty("front")
        private String front;

        @JsonProperty("back")
        private String back;
        
        @JsonProperty("topicTag")
        private String topicTag;
        
        @JsonProperty("type")
        private String type;
        
        @JsonProperty("tags")
        private List<String> tags;
    }
}
