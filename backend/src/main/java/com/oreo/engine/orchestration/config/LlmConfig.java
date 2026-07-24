package com.oreo.engine.orchestration.config;

import dev.langchain4j.model.chat.ChatLanguageModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import java.time.Duration;

import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import dev.langchain4j.model.googleai.GoogleAiGeminiStreamingChatModel;
import dev.langchain4j.model.googleai.GoogleAiGeminiChatModel;
import dev.langchain4j.web.search.WebSearchEngine;


@Configuration
public class LlmConfig {

    @Value("${oreo.llm.gemini-api-key:dummy-gemini-key}")
    private String apiKey;

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
}
