package com.oreo.engine.orchestration.config;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import dev.langchain4j.model.googleai.GoogleAiGeminiStreamingChatModel;
import dev.langchain4j.model.googleai.GoogleAiGeminiChatModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import com.oreo.engine.orchestration.pipelines.PlannerAssistant;
import com.oreo.engine.orchestration.pipelines.ChatSummarizer;
import com.oreo.engine.orchestration.tools.YouTubeSearchTool;
import dev.langchain4j.service.AiServices;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Proxy;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

@Configuration
public class LlmConfig {

    @Value("${oreo.llm.gemini-api-keys}")
    private List<String> apiKeys;

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
        List<ChatLanguageModel> models = apiKeys.stream()
                .map(key -> GoogleAiGeminiChatModel.builder()
                        .apiKey(key)
                        .modelName("gemini-3.5-flash-lite")
                        .temperature(0.7)
                        .maxRetries(3) // Increased retries for rate limits
                        .maxOutputTokens(8192)
                        .build())
                .collect(Collectors.toList());

        AtomicInteger index = new AtomicInteger(0);
        return (ChatLanguageModel) Proxy.newProxyInstance(
                ChatLanguageModel.class.getClassLoader(),
                new Class<?>[]{ChatLanguageModel.class},
                (proxy, method, args) -> {
                    int currentIndex = Math.abs(index.getAndIncrement() % models.size());
                    try {
                        return method.invoke(models.get(currentIndex), args);
                    } catch (InvocationTargetException e) {
                        throw e.getTargetException();
                    }
                }
        );
    }

    @Bean
    public StreamingChatLanguageModel geminiStreamingModel() {
        List<StreamingChatLanguageModel> models = apiKeys.stream()
                .map(key -> GoogleAiGeminiStreamingChatModel.builder()
                        .apiKey(key)
                        .modelName("gemini-3.5-flash-lite")
                        .temperature(0.7)
                        .build())
                .collect(Collectors.toList());

        AtomicInteger index = new AtomicInteger(0);
        return (StreamingChatLanguageModel) Proxy.newProxyInstance(
                StreamingChatLanguageModel.class.getClassLoader(),
                new Class<?>[]{StreamingChatLanguageModel.class},
                (proxy, method, args) -> {
                    int currentIndex = Math.abs(index.getAndIncrement() % models.size());
                    try {
                        return method.invoke(models.get(currentIndex), args);
                    } catch (InvocationTargetException e) {
                        throw e.getTargetException();
                    }
                }
        );
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
