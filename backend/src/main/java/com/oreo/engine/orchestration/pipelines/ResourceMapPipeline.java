package com.oreo.engine.orchestration.pipelines;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.web.search.WebSearchEngine;
import dev.langchain4j.web.search.WebSearchTool;
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
        public List<BranchNode> branches;
    }

    interface ResourceMapAiService {
        @SystemMessage("""
                You are a highly analytical High-Authority Librarian.
                Your task is to generate a topic tree for the given subject.
                For each sub-topic (branch), you MUST use your extensive internal knowledge to provide the MOST authoritative resource URL available.
                Prioritize official documentation, .edu domains, Wikipedia, and established tech platforms (e.g., MDN, AWS, Coursera).
                Generate 5 to 7 critical branch topics.
                Do NOT hallucinate URLs. Only provide exact URLs that you know exist.
                """)
        ResourceMapSchema generateMap(@UserMessage String subject);
    }

    private final ResourceMapAiService aiService;

    public ResourceMapPipeline(ChatLanguageModel chatLanguageModel, WebSearchEngine webSearchEngine) {
        dev.langchain4j.web.search.WebSearchTool searchTool = dev.langchain4j.web.search.WebSearchTool.from(webSearchEngine);
        this.aiService = AiServices.builder(ResourceMapAiService.class)
                .chatLanguageModel(chatLanguageModel)
                .tools(searchTool)
                .build();
    }

    public ResourceMapSchema generateResourceMap(String subject) {
        return aiService.generateMap(subject);
    }
}
