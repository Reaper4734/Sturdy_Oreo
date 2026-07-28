package com.oreo.engine.orchestration.config;

import dev.langchain4j.model.chat.ChatLanguageModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;



import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import dev.langchain4j.model.googleai.GoogleAiGeminiStreamingChatModel;
import dev.langchain4j.model.googleai.GoogleAiGeminiChatModel;

import com.oreo.engine.orchestration.pipelines.PlannerAssistant;
import com.oreo.engine.orchestration.pipelines.ChatSummarizer;
import com.oreo.engine.orchestration.tools.YouTubeSearchTool;
import dev.langchain4j.service.AiServices;

@Configuration
public class LlmConfig {

    @Value("${oreo.llm.gemini-api-key:dummy-gemini-key}")
    private String apiKey;

    @Value("${oreo.search.google-api-key:dummy-key}")
    private String googleSearchApiKey;

    @Value("${oreo.search.google-csx-id:dummy-csx}")
    private String googleCsxId;

    @Bean
    public dev.langchain4j.web.search.WebSearchEngine webSearchEngine() {
        return dev.langchain4j.web.search.google.customsearch.GoogleCustomWebSearchEngine.builder()
                .apiKey(googleSearchApiKey)
                .csi(googleCsxId)
                .build();
    }

    @Bean
    @Primary
    public ChatLanguageModel geminiModel() {
        return GoogleAiGeminiChatModel.builder()
                .apiKey(apiKey)
                .modelName("gemini-3.5-flash-lite")
                .temperature(0.7)
                .maxRetries(3) // Increased retries for rate limits
                .maxOutputTokens(2048)
                .build();
    }

    @Bean
    public StreamingChatLanguageModel geminiStreamingModel() {
        return GoogleAiGeminiStreamingChatModel.builder()
                .apiKey(apiKey)
                .modelName("gemini-3.5-flash-lite")
                .temperature(0.7)
                .build();
    }

    @Bean
    public PlannerAssistant plannerAssistant(ChatLanguageModel chatLanguageModel, YouTubeSearchTool youTubeSearchTool, dev.langchain4j.web.search.WebSearchEngine webSearchEngine) {
        dev.langchain4j.web.search.WebSearchTool searchTool = dev.langchain4j.web.search.WebSearchTool.from(webSearchEngine);
        return AiServices.builder(PlannerAssistant.class)
                .chatLanguageModel(chatLanguageModel)
                .tools(youTubeSearchTool, searchTool)
                .build();
    }

    @Bean
    public ChatSummarizer chatSummarizer(ChatLanguageModel chatLanguageModel) {
        return AiServices.builder(ChatSummarizer.class)
                .chatLanguageModel(chatLanguageModel)
                .build();
    }
}
