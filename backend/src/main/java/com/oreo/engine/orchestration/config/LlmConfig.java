package com.oreo.engine.orchestration.config;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.openai.OpenAiChatModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import java.time.Duration;

import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import dev.langchain4j.model.googleai.GoogleAiGeminiStreamingChatModel;
import dev.langchain4j.model.googleai.GoogleAiGeminiChatModel;

@Configuration
public class LlmConfig {

    @Value("${oreo.llm.gemini-api-key:dummy-gemini-key}")
    private String apiKey;

    @Bean
    @Primary
    public ChatLanguageModel geminiModel() {
        return GoogleAiGeminiChatModel.builder()
                .apiKey(apiKey)
                .modelName("gemini-3.1-flash-lite")
                .temperature(0.7)
                .maxOutputTokens(2048)
                .build();
    }

    @Bean
    public StreamingChatLanguageModel geminiStreamingModel() {
        return GoogleAiGeminiStreamingChatModel.builder()
                .apiKey(apiKey)
                .modelName("gemini-3.1-flash-lite")
                .temperature(0.7)
                .build();
    }

    @Bean
    public ChatLanguageModel mockModel() {
        return new ChatLanguageModel() {
            private final String JSON_RESPONSE = "```json\n" +
                    "{\n" +
                    "  \"track_id\": \"track_123\",\n" +
                    "  \"goal\": \"Build a real-time dashboard with React\",\n" +
                    "  \"nodes\": [\n" +
                    "    {\n" +
                    "      \"id\": \"step_1\",\n" +
                    "      \"title\": \"Initialize React App\",\n" +
                    "      \"type\": \"CODE_GENERATION\",\n" +
                    "      \"prereqs\": [],\n" +
                    "      \"rationale\": \"Sets up the foundational React project.\",\n" +
                    "      \"alternatives\": [\"Use Next.js\"]\n" +
                    "    }\n" +
                    "  ]\n" +
                    "}\n" +
                    "```";

            @Override
            public String generate(String userMessage) {
                return JSON_RESPONSE;
            }

            @Override
            public dev.langchain4j.model.output.Response<dev.langchain4j.data.message.AiMessage> generate(java.util.List<dev.langchain4j.data.message.ChatMessage> messages) {
                return dev.langchain4j.model.output.Response.from(
                    dev.langchain4j.data.message.AiMessage.from(JSON_RESPONSE)
                );
            }
        };
    }

}
