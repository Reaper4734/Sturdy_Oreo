package com.oreo.engine.orchestration.rag;

import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.data.embedding.Embedding;
import dev.langchain4j.retriever.Retriever;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Custom Hybrid Search Retriever.
 * Combines standard Vector similarity (pgvector) with Keyword matching (BM25 via ts_rank).
 * This runs parallel to the standard PgVectorEmbeddingStore but offers higher accuracy for specific keywords.
 */
@Component
public class HybridRetriever implements Retriever<TextSegment> {

    private final JdbcTemplate jdbcTemplate;
    private final EmbeddingModel embeddingModel;

    public HybridRetriever(JdbcTemplate jdbcTemplate, EmbeddingModel embeddingModel) {
        this.jdbcTemplate = jdbcTemplate;
        this.embeddingModel = embeddingModel;
    }

    @Override
    public List<TextSegment> find(String text) {
        // 1. Convert the user query into a vector
        Embedding queryEmbedding = embeddingModel.embed(text).content();
        
        // Convert array to PostgreSQL vector format: [0.1, 0.2, ...]
        String vectorLiteral = "[" + java.util.Arrays.toString(queryEmbedding.vector())
                .replace("[", "")
                .replace("]", "") + "]";

        // 2. Perform Hybrid Search Query (Vector Distance + Keyword Match)
        // We use plainto_tsquery for the keyword part and <=> for the vector distance.
        // We combine the scores: (1 - vector_distance) + ts_rank
        String sql = """
            SELECT text, 
                   (1 - (embedding <=> ?::vector)) AS vector_score,
                   ts_rank(to_tsvector('english', text), plainto_tsquery('english', ?)) AS keyword_score
            FROM document_embeddings
            ORDER BY ( (1 - (embedding <=> ?::vector)) * 0.7 + ts_rank(to_tsvector('english', text), plainto_tsquery('english', ?)) * 0.3 ) DESC
            LIMIT 5
        """;

        // Execute query
        return jdbcTemplate.query(sql,
                (rs, rowNum) -> TextSegment.from(rs.getString("text")),
                vectorLiteral, text, vectorLiteral, text
        );
    }
}
