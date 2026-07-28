package com.oreo.engine.orchestration.services;

import com.oreo.engine.orchestration.schemas.GraphEdge;
import com.oreo.engine.orchestration.schemas.KnowledgeGraphSchema;
import com.oreo.engine.orchestration.schemas.KnowledgeGraphSchema.KnowledgeNode;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.stream.Collectors;

@Component
public class GraphOptimizer {

    public KnowledgeGraphSchema optimize(KnowledgeGraphSchema graph) {
        if (graph.getNodes() == null || graph.getEdges() == null) {
            return graph;
        }

        // 1. Remove duplicate nodes by ID (keep first occurrence)
        Map<String, KnowledgeNode> uniqueNodes = new LinkedHashMap<>();
        for (KnowledgeNode node : graph.getNodes()) {
            uniqueNodes.putIfAbsent(node.getId(), node);
        }
        
        // 2. Remove duplicate and self edges
        Set<String> validIds = uniqueNodes.keySet();
        Set<String> seenEdges = new HashSet<>();
        List<GraphEdge> cleanEdges = new ArrayList<>();

        for (GraphEdge edge : graph.getEdges()) {
            // Ignore self edges
            if (edge.getFrom().equals(edge.getTo())) continue;
            
            // Ignore edges to/from non-existent nodes
            if (!validIds.contains(edge.getFrom()) || !validIds.contains(edge.getTo())) continue;

            String edgeKey = edge.getFrom() + "->" + edge.getTo();
            if (seenEdges.add(edgeKey)) {
                cleanEdges.add(edge);
            }
        }

        // 3. Ensure single root and connectivity (Fallback: link orphans to the first node)
        if (!uniqueNodes.isEmpty()) {
            String primaryRootId = uniqueNodes.keySet().iterator().next(); // naive root

            Set<String> nodesWithIncoming = cleanEdges.stream()
                .map(GraphEdge::getTo)
                .collect(Collectors.toSet());

            for (String id : validIds) {
                // If it's not the primary root and has no incoming edges, link it from the root
                if (!id.equals(primaryRootId) && !nodesWithIncoming.contains(id)) {
                    cleanEdges.add(new GraphEdge(primaryRootId, id));
                }
            }
        }

        graph.setNodes(new ArrayList<>(uniqueNodes.values()));
        graph.setEdges(cleanEdges);

        return graph;
    }
}
