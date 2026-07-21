package com.oreo.engine.orchestration.config;

import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.model.googleai.GoogleAiEmbeddingModel;
import dev.langchain4j.store.embedding.EmbeddingStore;
import dev.langchain4j.store.embedding.pgvector.PgVectorEmbeddingStore;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RagConfig {

    @Value("${oreo.llm.gemini-api-key:dummy}")
    private String geminiApiKey;

    @Value("${spring.datasource.url}")
    private String dbUrl;

    @Value("${spring.datasource.username}")
    private String dbUser;

    @Value("${spring.datasource.password}")
    private String dbPassword;

    @Bean
    public EmbeddingModel embeddingModel() {
        return GoogleAiEmbeddingModel.builder()
                .apiKey(geminiApiKey)
                .modelName("text-embedding-004")
                .build();
    }

    @Bean
    public EmbeddingStore<TextSegment> embeddingStore() {
        // Strip jdbc: prefix for PGVector
        String cleanUrl = dbUrl.replace("jdbc:", "");
        
        return PgVectorEmbeddingStore.builder()
                .host("localhost") // Since we are developing locally
                .port(5432)
                .database("oreo_db")
                .user(dbUser)
                .password(dbPassword)
                .table("document_embeddings")
                .dimension(768) // Match the V14 migration
                .build();
    }
}
