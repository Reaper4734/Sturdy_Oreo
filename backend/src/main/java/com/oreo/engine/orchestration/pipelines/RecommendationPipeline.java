package com.oreo.engine.orchestration.pipelines;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RecommendationPipeline {

    private final RecommendationAiService recommendationAiService;

    interface RecommendationAiService {
        @SystemMessage("""
                You are a curriculum recommendation engine.
                The user will provide their domain or field of interest (e.g., "Computer Science", "Finance").
                You must return exactly 3 highly relevant technical subjects or skills they should learn next.
                Output ONLY a JSON array of 3 strings. Example: ["Java", "Data Structures", "System Design"]
                Do NOT output markdown blocks or conversational text.
                """)
        String recommendSubjects(@UserMessage String domain);
    }

    public RecommendationPipeline(ChatLanguageModel primaryChatModel) {
        this.recommendationAiService = AiServices.builder(RecommendationAiService.class)
                .chatLanguageModel(primaryChatModel)
                .build();
    }

    @Cacheable("recommendations")
    public List<String> getRecommendations(String domain) {
        String rawOutput = recommendationAiService.recommendSubjects("My domain is: " + domain);
        if (rawOutput == null || rawOutput.isBlank()) {
            return List.of(domain + " Fundamentals", domain + " Core Patterns", "Applied " + domain);
        }

        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            // Clean code fences if present
            String cleaned = rawOutput.replaceAll("```json", "").replaceAll("```", "").trim();
            int startIdx = cleaned.indexOf('[');
            int endIdx = cleaned.lastIndexOf(']');
            if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
                cleaned = cleaned.substring(startIdx, endIdx + 1);
                List<String> list = mapper.readValue(cleaned, new com.fasterxml.jackson.core.type.TypeReference<List<String>>() {});
                if (!list.isEmpty()) {
                    return list;
                }
            }
        } catch (Exception ignored) {
        }

        // Safe fallback tokenization
        String[] subjects = rawOutput.replace("[", "").replace("]", "").replace("\"", "").split(",");
        java.util.List<String> result = new java.util.ArrayList<>();
        for (String s : subjects) {
            String trimmed = s.trim();
            if (!trimmed.isEmpty()) {
                result.add(trimmed);
            }
        }
        return result.isEmpty() ? List.of(domain + " Foundations") : result;
    }
}
