package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class JsonSchemaValidationTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void shouldDeserializeDagOutputSchemaCorrectly() throws Exception {
        String json = """
            {
              "track_id": "track-77",
              "goal": "Master Quantum Computing Basics",
              "nodes": [
                {
                  "id": "n1",
                  "title": "Complex Vectors",
                  "type": "visual_theory",
                  "prereqs": [],
                  "rationale": "Foundational math needed for Qubits.",
                  "alternatives": ["Linear Algebra Basics"]
                },
                {
                  "id": "n2",
                  "title": "Single Qubit Gates",
                  "type": "interactive",
                  "prereqs": ["n1"],
                  "rationale": "Manipulating single qubit states.",
                  "alternatives": ["Bloch Sphere Intro"]
                }
              ]
            }
            """;

        DagOutputSchema schema = objectMapper.readValue(json, DagOutputSchema.class);

        assertNotNull(schema);
        assertEquals("track-77", schema.getTrackId());
        assertEquals("Master Quantum Computing Basics", schema.getGoal());
        assertEquals(2, schema.getNodes().size());
        assertEquals("n1", schema.getNodes().get(0).getId());
        assertEquals("visual_theory", schema.getNodes().get(0).getType());
        assertEquals(1, schema.getNodes().get(1).getPrereqs().size());
        assertEquals("n1", schema.getNodes().get(1).getPrereqs().get(0));
    }

    @Test
    void shouldDeserializeProfilerOutputSchemaCorrectly() throws Exception {
        String json = """
            {
              "reply_to_user": "Great job! Let us explore data structures.",
              "internal_state": {
                "domain_identified": true,
                "eq_identified": true,
                "modality_identified": false,
                "confidence_score": 85,
                "current_inferred_persona": {
                  "domain": "Computer Science",
                  "iq_logic": "High Logical-Mathematical",
                  "eq_resilience": "Moderate Resilience"
                }
              }
            }
            """;

        ProfilerOutputSchema schema = objectMapper.readValue(json, ProfilerOutputSchema.class);

        assertNotNull(schema);
        assertEquals("Great job! Let us explore data structures.", schema.getReplyToUser());
        assertNotNull(schema.getInternalState());
        assertTrue(schema.getInternalState().isDomainIdentified());
        assertTrue(schema.getInternalState().isEqIdentified());
        assertFalse(schema.getInternalState().isModalityIdentified());
        assertEquals(85, schema.getInternalState().getConfidenceScore());
        assertEquals("Computer Science", schema.getInternalState().getCurrentInferredPersona().getDomain());
    }

    @Test
    void shouldHandlePartialOrNullJsonFieldsInProfilerOutputSchema() throws Exception {
        String json = """
            {
              "reply_to_user": "Partial response",
              "internal_state": null
            }
            """;

        ProfilerOutputSchema schema = objectMapper.readValue(json, ProfilerOutputSchema.class);

        assertNotNull(schema);
        assertEquals("Partial response", schema.getReplyToUser());
        assertNull(schema.getInternalState());
    }
}
