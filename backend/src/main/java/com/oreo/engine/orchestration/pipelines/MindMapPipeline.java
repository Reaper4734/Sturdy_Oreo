package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.schemas.MindMapSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class MindMapPipeline {

    interface MindMapAiService {
        @SystemMessage("""
                You are a subject-matter expert and curriculum designer.
                
                Given a learning subject, generate a concept mind map as a JSON object.
                
                STRUCTURE RULES:
                - Exactly ONE root node at depthLevel 0 (the subject itself)
                - 4 to 7 primary branch nodes at depthLevel 1 (major sub-topics)
                - 2 to 4 leaf nodes at depthLevel 2 under each branch (specific concepts)
                - No deeper nesting. Maximum depth is 2.
                
                FIELD RULES:
                - "id": unique string (format: root_1, n1, n1_1, n2, n2_1, etc.)
                - "label": short text, 2 to 5 words maximum
                - "depthLevel": integer (0, 1, or 2)
                - "isTerminal": false for depth 0 and 1, true for depth 2
                - "children": array of child nodes (empty array [] for leaf nodes)
                
                OUTPUT:
                Return ONLY the raw JSON object. No markdown code fences. No explanation.
                No text before or after the JSON.
                """)
        MindMapSchema generateMap(@UserMessage String prompt);
    }

    private final MindMapAiService aiService;

    public MindMapPipeline(ChatLanguageModel chatLanguageModel) {
        this.aiService = AiServices.builder(MindMapAiService.class)
                .chatLanguageModel(chatLanguageModel)
                .build();
    }

    public MindMapSchema generateMindMap(String subjectTitle) {
        String prompt = "Generate a mind map for the subject: " + subjectTitle;
        
        MindMapSchema schema = null;
        Exception lastError = null;
        
        for (int attempt = 1; attempt <= 2; attempt++) {
            try {
                schema = aiService.generateMap(prompt);
                validateSchema(schema);
                break; // Validation passed
            } catch (Exception e) {
                lastError = e;
                if (attempt == 2) {
                    throw new RuntimeException("Failed to generate a valid Mind Map after 2 attempts: " + e.getMessage(), e);
                }
            }
        }
        
        if (schema.getSubjectId() == null || schema.getSubjectId().isEmpty() || "string".equals(schema.getSubjectId())) {
            schema.setSubjectId("s_" + UUID.randomUUID().toString().substring(0, 8));
        }
        
        return schema;
    }

    private void validateSchema(MindMapSchema schema) {
        if (schema.getRootNode() == null) throw new IllegalArgumentException("rootNode is missing");
        if (schema.getRootNode().getDepthLevel() != 0) throw new IllegalArgumentException("rootNode depthLevel must be 0");
        
        java.util.Set<String> ids = new java.util.HashSet<>();
        validateNode(schema.getRootNode(), 0, ids);
    }

    private void validateNode(MindMapSchema.ConceptNode node, int expectedDepth, java.util.Set<String> ids) {
        if (node.getDepthLevel() != expectedDepth) {
            throw new IllegalArgumentException("Node " + node.getId() + " has incorrect depth " + node.getDepthLevel() + ", expected " + expectedDepth);
        }
        if (expectedDepth == 0 || expectedDepth == 1) {
            if (node.isTerminal()) throw new IllegalArgumentException("Node " + node.getId() + " at depth " + expectedDepth + " cannot be terminal");
        } else if (expectedDepth == 2) {
            if (!node.isTerminal()) throw new IllegalArgumentException("Node " + node.getId() + " at depth 2 must be terminal");
        } else {
            throw new IllegalArgumentException("Depth 3+ is not allowed (node " + node.getId() + ")");
        }
        
        if (!ids.add(node.getId())) {
            throw new IllegalArgumentException("Duplicate ID found: " + node.getId());
        }
        
        if (node.getChildren() != null) {
            for (MindMapSchema.ConceptNode child : node.getChildren()) {
                validateNode(child, expectedDepth + 1, ids);
            }
        }
    }
}
