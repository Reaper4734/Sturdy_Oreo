package com.oreo.engine.orchestration.pipelines;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AgentsAndModelPipelinesTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void flashcardExtractor_ShouldAdhereToSerializationContract() {
        assertTrue(objectMapper.canSerialize(FlashcardGeneratorPipeline.ExtractedCardWrapper.class),
                "ExtractedCardWrapper must be serializable by Jackson");
        assertTrue(objectMapper.canDeserialize(objectMapper.constructType(FlashcardGeneratorPipeline.ExtractedCardWrapper.class)),
                "ExtractedCardWrapper must be deserializable by Jackson");

        assertTrue(objectMapper.canSerialize(FlashcardGeneratorPipeline.ExtractedCard.class),
                "ExtractedCard must be serializable by Jackson");
        assertTrue(objectMapper.canDeserialize(objectMapper.constructType(FlashcardGeneratorPipeline.ExtractedCard.class)),
                "ExtractedCard must be deserializable by Jackson");
    }
}

