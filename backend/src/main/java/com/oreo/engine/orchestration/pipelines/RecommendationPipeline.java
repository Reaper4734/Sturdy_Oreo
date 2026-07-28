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
        
        // Very lazy parser for JSON array string
        rawOutput = rawOutput.replace("[", "").replace("]", "").replace("\"", "").trim();
        String[] subjects = rawOutput.split(",");
        
        return List.of(subjects[0].trim(), subjects[1].trim(), subjects[2].trim());
    }
}
