package com.oreo.engine.orchestration.rag;

import com.oreo.engine.orchestration.pipelines.RagIngestionPipeline;
import dev.langchain4j.data.embedding.Embedding;
import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.rag.content.Content;
import dev.langchain4j.rag.query.Query;
import dev.langchain4j.store.embedding.EmbeddingStore;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.mock.web.MockMultipartFile;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RagPipelineTest {

    @Mock
    private EmbeddingStore<TextSegment> embeddingStore;

    @Mock
    private EmbeddingModel embeddingModel;

    @Mock
    private JdbcTemplate jdbcTemplate;

    private RagIngestionPipeline ingestionPipeline;
    private HybridRetriever hybridRetriever;

    @BeforeEach
    void setUp() {
        ingestionPipeline = new RagIngestionPipeline(embeddingStore, embeddingModel);
        hybridRetriever = new HybridRetriever(jdbcTemplate, embeddingModel);
    }

    @Test
    void ingestDocument_ShouldChunkAndEmbed_WhenValidFileProvided() throws Exception {
        String content = "Header section.\n\nFirst paragraph content detailing RAG systems.\n\nSecond paragraph content with code: x < y & a > b.";
        MockMultipartFile file = new MockMultipartFile("file", "lecture.txt", "text/plain", content.getBytes());

        dev.langchain4j.model.output.Response<Embedding> mockResponse =
                dev.langchain4j.model.output.Response.from(Embedding.from(new float[]{0.1f, 0.2f, 0.3f}));

        when(embeddingModel.embed(any(TextSegment.class))).thenReturn(mockResponse);

        int chunkCount = ingestionPipeline.ingestDocument(file);

        assertEquals(3, chunkCount, "Should split document into 3 non-empty double-newline chunks");
        verify(embeddingStore, times(3)).add(any(Embedding.class), any(TextSegment.class));

        ArgumentCaptor<TextSegment> segmentCaptor = ArgumentCaptor.forClass(TextSegment.class);
        verify(embeddingStore, times(3)).add(any(Embedding.class), segmentCaptor.capture());

        List<TextSegment> capturedSegments = segmentCaptor.getAllValues();
        assertTrue(capturedSegments.get(2).text().contains("x < y & a > b"), "Raw text symbols should be preserved without HTML character escaping");
        assertEquals("lecture.txt", capturedSegments.get(0).metadata().getString("filename"));
    }

    @Test
    void ingestDocument_ShouldSkipEmptyChunks() throws Exception {
        String content = "Chunk 1\n\n\n\nChunk 2\n\n   \n\nChunk 3";
        MockMultipartFile file = new MockMultipartFile("file", "test.txt", "text/plain", content.getBytes());

        dev.langchain4j.model.output.Response<Embedding> mockResponse =
                dev.langchain4j.model.output.Response.from(Embedding.from(new float[]{0.5f, 0.5f}));

        when(embeddingModel.embed(any(TextSegment.class))).thenReturn(mockResponse);

        int chunkCount = ingestionPipeline.ingestDocument(file);

        assertEquals(3, chunkCount, "Should ignore empty whitespace-only chunks");
    }

    @Test
    void hybridRetrieve_ShouldFormulateVectorAndKeywordSql() {
        Query query = new Query("How does backpropagation work in neural networks?");
        dev.langchain4j.model.output.Response<Embedding> mockResponse =
                dev.langchain4j.model.output.Response.from(Embedding.from(new float[]{0.1f, 0.2f}));

        when(embeddingModel.embed(anyString())).thenReturn(mockResponse);
        when(jdbcTemplate.query(anyString(), any(RowMapper.class), any(), any(), any(), any()))
                .thenReturn(List.of(TextSegment.from("Neural network backpropagation relies on gradient descent.")));

        List<Content> results = hybridRetriever.retrieve(query);

        assertNotNull(results);
        assertEquals(1, results.size());
        assertEquals("Neural network backpropagation relies on gradient descent.", results.get(0).textSegment().text());
        verify(jdbcTemplate, times(1)).query(contains("document_embeddings"), any(RowMapper.class), any(), any(), any(), any());
    }
}
