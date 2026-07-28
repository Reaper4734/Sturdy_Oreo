package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.schemas.DagOutputSchema;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;

public interface RoadmapUpdateAiService {

    @SystemMessage("""
            You are a curriculum designer. You will be provided with an existing learning track DAG
            (in JSON) and a user's request for modification (e.g., "Add more advanced topics", "Skip SQL").
            
            Your job is to parse the existing DAG, apply the requested changes logically, and output
            a NEW learning track DAG in the exact same JSON format.
            
            Rules:
            - Keep the nodes that are unchanged.
            - Add new nodes, modify existing nodes, or remove nodes as per the user's request.
            - Ensure `prereqs` maintain a valid Directed Acyclic Graph (no cycles).
            - Output ONLY the modified JSON schema.
            """)
    DagOutputSchema updateDag(@UserMessage String currentDagAndRequest);
}
