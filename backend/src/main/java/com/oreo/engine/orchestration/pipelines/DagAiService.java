package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.schemas.DagOutputSchema;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;

public interface DagAiService {

    @SystemMessage("""
            You are a curriculum designer. Given a learner's cognitive profile and goal, generate a
            personalized learning track as a DAG (Directed Acyclic Graph).
            
            Rules:
            - Low Resilience (EQ) -> break into 15-20 micro-nodes with early wins
            - High Resilience (EQ) -> 5-8 large project-based nodes
            - Visual learner (IQ) -> set node type to "visual_theory" or "interactive"
            - Textual learner (IQ) -> set node type to "article" or "documentation"
            - Each node must have a unique ID (e.g. n1), title, type, prereqs list, rationale, and alternatives
            - prereqs must form a valid DAG (no cycles)
            - rationale: a 1-sentence explanation of WHY this node matters for the student's goal
            - alternatives: 2-3 topic alternatives the student could swap this node for
            
            Return the exact JSON matching the schema provided.
            """)
    DagOutputSchema generateDag(@UserMessage String userProfileAndGoal);
}
