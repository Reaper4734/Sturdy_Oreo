package com.oreo.engine.orchestration.config;

import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.model.googleai.GoogleAiEmbeddingModel;
import dev.langchain4j.store.embedding.EmbeddingStore;
import dev.langchain4j.store.embedding.pgvector.PgVectorEmbeddingStore;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.net.URI;

@Configuration
public class RagConfig {

    @Value("${oreo.llm.gemini-api-key:dummy-gemini-key}")
    private String geminiApiKey;

    @Value("${spring.datasource.url}")
    private String dbUrl;

    @Value("${spring.datasource.username}")
    private String dbUser;

    @Value("${spring.datasource.password}")
    private String dbPassword;

    @Bean
    public EmbeddingModel embeddingModel() {
        return new dev.langchain4j.model.embedding.onnx.allminilml6v2.AllMiniLmL6V2EmbeddingModel();
    }

    @Bean
    public EmbeddingStore<TextSegment> embeddingStore() {
        // Parse host, port, database from the JDBC URL dynamically
        // e.g. jdbc:postgresql://localhost:5432/oreo_db
        String cleanUrl = dbUrl.replace("jdbc:postgresql://", "");
        String[] hostPortDb = cleanUrl.split("/");
        String[] hostPort = hostPortDb[0].split(":");
        
        String host = hostPort[0];
        int port = hostPort.length > 1 ? Integer.parseInt(hostPort[1]) : 5432;
        String database = hostPortDb.length > 1 ? hostPortDb[1] : "oreo_db";

        return PgVectorEmbeddingStore.builder()
                .host(host)
                .port(port)
                .database(database)
                .user(dbUser)
                .password(dbPassword)
                .table("document_embeddings")
                .dimension(384)
                .build();
    }
}
