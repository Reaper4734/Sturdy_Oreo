package com.oreo.engine.orchestration.services;

import com.oreo.engine.orchestration.schemas.DagOutputSchema;
import com.oreo.engine.orchestration.schemas.GraphEdge;
import com.oreo.engine.orchestration.schemas.KnowledgeGraphSchema;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class DagBuilder {

    public KnowledgeGraphSchema buildKnowledgeGraph(DagOutputSchema dagOutput) {
        KnowledgeGraphSchema kg = new KnowledgeGraphSchema();
        kg.setCourseTitle(dagOutput.getCourseTitle() != null ? dagOutput.getCourseTitle() : dagOutput.getGoal());
        kg.setVersion(dagOutput.getVersion() != null ? dagOutput.getVersion() : 1);
        kg.setGraphType(dagOutput.getGraphType() != null ? dagOutput.getGraphType() : "DAG");
        kg.setDifficulty(dagOutput.getDifficulty() != null ? dagOutput.getDifficulty() : "Intermediate");
        kg.setEstimatedHours(dagOutput.getEstimatedHours() != null ? dagOutput.getEstimatedHours() : 0);
        kg.setGeneratedAt(Instant.now().toString());

        List<KnowledgeGraphSchema.KnowledgeNode> kgNodes = new ArrayList<>();
        List<GraphEdge> kgEdges = new ArrayList<>();

        if (dagOutput.getNodes() != null) {
            for (DagOutputSchema.DagNode dagNode : dagOutput.getNodes()) {
                // Map Node
                KnowledgeGraphSchema.KnowledgeNode kn = new KnowledgeGraphSchema.KnowledgeNode();
                kn.setId(dagNode.getId());
                kn.setTitle(dagNode.getTitle());
                kn.setType(dagNode.getType());
                kn.setEstimatedHours(dagNode.getEstimatedHours());
                kn.setDifficulty(dagNode.getDifficulty());
                kn.setTags(dagNode.getTags());
                kn.setRationale(dagNode.getRationale());
                kn.setAlternatives(dagNode.getAlternatives());
                kgNodes.add(kn);

                // Map Edges from Prerequisites
                if (dagNode.getPrereqs() != null) {
                    for (String prereqId : dagNode.getPrereqs()) {
                        kgEdges.add(new GraphEdge(prereqId, dagNode.getId()));
                    }
                }
            }
        }

        kg.setNodes(kgNodes);
        kg.setEdges(kgEdges);

        return kg;
    }
}
