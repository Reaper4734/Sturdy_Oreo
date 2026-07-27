package com.oreo.engine.orchestration.services;

import com.oreo.engine.orchestration.schemas.GraphEdge;
import com.oreo.engine.orchestration.schemas.KnowledgeGraphSchema;
import com.oreo.engine.orchestration.schemas.KnowledgeGraphSchema.KnowledgeNode;
import com.oreo.engine.orchestration.schemas.NodeType;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class GraphValidator {

    public void validate(KnowledgeGraphSchema graph) {
        if (graph.getNodes() == null || graph.getNodes().isEmpty()) {
            throw new IllegalArgumentException("Graph must have at least one node.");
        }
        
        List<KnowledgeNode> nodes = graph.getNodes();
        List<GraphEdge> edges = graph.getEdges() != null ? graph.getEdges() : new ArrayList<>();

        // 1. No duplicate IDs
        Set<String> nodeIds = new HashSet<>();
        for (KnowledgeNode node : nodes) {
            if (!nodeIds.add(node.getId())) {
                throw new IllegalArgumentException("Duplicate node ID found: " + node.getId());
            }
        }

        // 2. Valid Enums (handled by Jackson deserialization, but we can verify it's not null)
        for (KnowledgeNode node : nodes) {
            if (node.getType() == null) {
                throw new IllegalArgumentException("Node type cannot be null for node: " + node.getId());
            }
        }

        // 3. Node count within limits
        if (nodes.size() > 200) {
            throw new IllegalArgumentException("Node count exceeds maximum limit (200).");
        }

        // 4. Edge count sanity
        if (edges.size() > nodes.size() * 3) {
            throw new IllegalArgumentException("Edge count seems unreasonably high.");
        }

        // Check self edges and duplicate edges
        Set<String> uniqueEdges = new HashSet<>();
        for (GraphEdge edge : edges) {
            if (edge.getFrom().equals(edge.getTo())) {
                throw new IllegalArgumentException("Self edge detected on node: " + edge.getFrom());
            }
            String edgeKey = edge.getFrom() + "->" + edge.getTo();
            if (!uniqueEdges.add(edgeKey)) {
                throw new IllegalArgumentException("Duplicate edge detected: " + edgeKey);
            }
            if (!nodeIds.contains(edge.getFrom()) || !nodeIds.contains(edge.getTo())) {
                throw new IllegalArgumentException("Edge references non-existent node: " + edgeKey);
            }
        }

        // Calculate indegree and outdegree
        Map<String, Integer> inDegree = new HashMap<>();
        Map<String, Integer> outDegree = new HashMap<>();
        Map<String, List<String>> adjList = new HashMap<>();
        for (String id : nodeIds) {
            inDegree.put(id, 0);
            outDegree.put(id, 0);
            adjList.put(id, new ArrayList<>());
        }

        for (GraphEdge edge : edges) {
            inDegree.put(edge.getTo(), inDegree.get(edge.getTo()) + 1);
            outDegree.put(edge.getFrom(), outDegree.get(edge.getFrom()) + 1);
            adjList.get(edge.getFrom()).add(edge.getTo());
        }

        // 5. Exactly one root, 6. At least one leaf, 7. No orphan nodes
        int rootCount = 0;
        int leafCount = 0;
        for (String id : nodeIds) {
            int in = inDegree.get(id);
            int out = outDegree.get(id);
            if (in == 0 && out == 0 && nodes.size() > 1) {
                throw new IllegalArgumentException("Orphan node detected: " + id);
            }
            if (in == 0) rootCount++;
            if (out == 0) leafCount++;
        }

        if (rootCount != 1) {
            throw new IllegalArgumentException("Graph must have exactly one root. Found: " + rootCount);
        }
        if (leafCount == 0) {
            throw new IllegalArgumentException("Graph must have at least one leaf.");
        }

        // 8. Project / Assessment has incoming edge
        for (KnowledgeNode node : nodes) {
            if (node.getType() == NodeType.PROJECT || node.getType() == NodeType.ASSESSMENT) {
                if (inDegree.get(node.getId()) == 0) {
                    throw new IllegalArgumentException("Project/Assessment node must have incoming edge: " + node.getId());
                }
            }
        }

        // 9. Capstone is final leaf (outdegree 0)
        boolean hasCapstone = false;
        for (KnowledgeNode node : nodes) {
            if (node.getType() == NodeType.CAPSTONE) {
                hasCapstone = true;
                if (outDegree.get(node.getId()) > 0) {
                    throw new IllegalArgumentException("Capstone must be a final leaf (no outgoing edges): " + node.getId());
                }
            }
        }
        if (!hasCapstone) {
            throw new IllegalArgumentException("Graph must contain at least one Capstone node.");
        }

        // 10. Cycle detection (Kahn's algorithm)
        Queue<String> queue = new LinkedList<>();
        for (String id : nodeIds) {
            if (inDegree.get(id) == 0) {
                queue.add(id);
            }
        }
        
        int visitedNodes = 0;
        while (!queue.isEmpty()) {
            String u = queue.poll();
            visitedNodes++;
            for (String v : adjList.get(u)) {
                inDegree.put(v, inDegree.get(v) - 1);
                if (inDegree.get(v) == 0) {
                    queue.add(v);
                }
            }
        }
        if (visitedNodes != nodeIds.size()) {
            throw new IllegalArgumentException("Graph contains cycles or disconnected components (not fully reachable).");
        }
    }
}
