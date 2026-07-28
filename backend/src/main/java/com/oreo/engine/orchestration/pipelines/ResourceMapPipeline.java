package com.oreo.engine.orchestration.pipelines;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oreo.engine.orchestration.model.CurriculumCache;
import com.oreo.engine.orchestration.repository.CurriculumCacheRepository;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.web.search.WebSearchEngine;

import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ResourceMapPipeline {

    public static class AuthoritativeResource {
        public String title;
        public String url;
        public int authorityScore;
        public String sourceType;
    }

    public static class BranchNode {
        public String topic;
        public String rationale;
        public AuthoritativeResource authoritativeResource;
    }

    public static class ResourceMapSchema {
        public String subject;
        public String mermaidGraph;
        public List<BranchNode> branches;
    }

    interface ResourceMapAiService {
        @SystemMessage("""
                You are an authoritative Curriculum Planner and Resource Librarian.
                Your task is to generate a comprehensive topic tree for the given subject.
                There is NO artificial limit on the number of branch topics. Generate as many as needed to fully and accurately represent the curriculum you find.
                
                CRITICAL PERFORMANCE RULE: You must execute EXACTLY ONE web search (e.g. "GeeksForGeeks [Subject] Curriculum"). 
                Do NOT execute a separate search for every single branch. Read the single curriculum result, cross-verify it with your internal knowledge, and generate the complete JSON tree.
                For each sub-topic, provide the root URL of the curriculum you found.

                You must ALSO output a highly detailed, visually attractive Mermaid.js graph string in the 'mermaidGraph' field.
                Use 'graph TD'. Use square brackets [] for core nodes and parenthesis () for sub-nodes. Do NOT wrap it in markdown backticks, just the raw Mermaid code.
                """)
        ResourceMapSchema generateMap(@UserMessage String subject);
    }

    private final ResourceMapAiService aiService;
    private final CurriculumCacheRepository repository;
    private final ObjectMapper objectMapper;

    public ResourceMapPipeline(ChatLanguageModel chatLanguageModel, WebSearchEngine webSearchEngine, CurriculumCacheRepository repository, ObjectMapper objectMapper) {
        this.repository = repository;
        this.objectMapper = objectMapper;
        dev.langchain4j.web.search.WebSearchTool searchTool = dev.langchain4j.web.search.WebSearchTool.from(webSearchEngine);
        this.aiService = AiServices.builder(ResourceMapAiService.class)
                .chatLanguageModel(chatLanguageModel)
                .tools(searchTool)
                .build();
    }

    public ResourceMapSchema generateResourceMap(String subject) {
        CurriculumCache cache = repository.findBySubject(subject).orElseGet(() -> {
            CurriculumCache newCache = new CurriculumCache();
            newCache.setSubject(subject);
            return newCache;
        });

        if (cache.getResourceMapData() != null) {
            try {
                return objectMapper.convertValue(cache.getResourceMapData(), ResourceMapSchema.class);
            } catch (Exception ignored) {}
        }

        ResourceMapSchema schema = aiService.generateMap(subject);
        
        // Clean up mermaid graph just in case
        if (schema.mermaidGraph != null) {
            String rawMermaid = schema.mermaidGraph;
            if (rawMermaid.startsWith("```mermaid")) rawMermaid = rawMermaid.replace("```mermaid", "");
            if (rawMermaid.startsWith("```")) rawMermaid = rawMermaid.replace("```", "");
            if (rawMermaid.endsWith("```")) rawMermaid = rawMermaid.substring(0, rawMermaid.length() - 3);
            schema.mermaidGraph = rawMermaid.trim();
        }

        cache.setResourceMapData(schema);
        cache.setMermaidData(schema.mermaidGraph);
        repository.save(cache);
        return schema;
    }
}
