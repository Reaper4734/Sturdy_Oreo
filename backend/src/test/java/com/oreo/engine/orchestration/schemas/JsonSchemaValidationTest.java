package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Structural schema introspection test.
 * Verifies that DTO schemas adhere to Jackson serialization contracts
 * without relying on synthetic or hardcoded domain mock data.
 */
class JsonSchemaValidationTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void validateMindMapSchemaStructure() {
        // Assert Jackson can construct and introspect the class without errors
        assertTrue(objectMapper.canSerialize(MindMapSchema.class),
                "MindMapSchema must be serializable by Jackson");
        assertTrue(objectMapper.canDeserialize(objectMapper.constructType(MindMapSchema.class)),
                "MindMapSchema must be deserializable by Jackson");

        // Verify every field has explicit @JsonProperty annotations
        for (Field field : MindMapSchema.class.getDeclaredFields()) {
            if (!Modifier.isStatic(field.getModifiers())) {
                assertNotNull(field.getAnnotation(com.fasterxml.jackson.annotation.JsonProperty.class),
                        "Field '" + field.getName() + "' in MindMapSchema must be annotated with @JsonProperty");
            }
        }

        // Verify nested ConceptNode structure
        for (Field field : MindMapSchema.ConceptNode.class.getDeclaredFields()) {
            if (!Modifier.isStatic(field.getModifiers())) {
                assertNotNull(field.getAnnotation(com.fasterxml.jackson.annotation.JsonProperty.class),
                        "Field '" + field.getName() + "' in ConceptNode must be annotated with @JsonProperty");
            }
        }
    }

    @Test
    void validateProfilerOutputSchemaStructure() {
        assertTrue(objectMapper.canSerialize(ProfilerOutputSchema.class),
                "ProfilerOutputSchema must be serializable by Jackson");
        assertTrue(objectMapper.canDeserialize(objectMapper.constructType(ProfilerOutputSchema.class)),
                "ProfilerOutputSchema must be deserializable by Jackson");

        for (Field field : ProfilerOutputSchema.class.getDeclaredFields()) {
            if (!Modifier.isStatic(field.getModifiers())) {
                assertNotNull(field.getAnnotation(com.fasterxml.jackson.annotation.JsonProperty.class),
                        "Field '" + field.getName() + "' in ProfilerOutputSchema must be annotated with @JsonProperty");
            }
        }

        for (Field field : ProfilerOutputSchema.InternalState.class.getDeclaredFields()) {
            if (!Modifier.isStatic(field.getModifiers())) {
                assertNotNull(field.getAnnotation(com.fasterxml.jackson.annotation.JsonProperty.class),
                        "Field '" + field.getName() + "' in InternalState must be annotated with @JsonProperty");
            }
        }
    }
}
