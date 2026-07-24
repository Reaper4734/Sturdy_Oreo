package com.oreo.engine.orchestration.pipelines;

import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.store.embedding.EmbeddingStore;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.util.HtmlUtils;

import java.nio.charset.StandardCharsets;

@Service
public class RagIngestionPipeline {

    private final EmbeddingStore<TextSegment> embeddingStore;
    private final EmbeddingModel embeddingModel;

    public RagIngestionPipeline(EmbeddingStore<TextSegment> embeddingStore, EmbeddingModel embeddingModel) {
        this.embeddingStore = embeddingStore;
        this.embeddingModel = embeddingModel;
    }

    public int ingestDocument(MultipartFile file) throws Exception {
        String rawContent = new String(file.getBytes(), StandardCharsets.UTF_8);
        String[] chunks = rawContent.split("\n\n");
        int count = 0;
        String fileName = file.getOriginalFilename() != null ? file.getOriginalFilename() : "Uploaded_Document.txt";

        for (String chunk : chunks) {
            if (chunk.trim().isEmpty()) continue;
            dev.langchain4j.data.document.Metadata metadata = new dev.langchain4j.data.document.Metadata();
            metadata.add("filename", fileName);
            TextSegment segment = TextSegment.from(chunk.trim(), metadata);
            dev.langchain4j.data.embedding.Embedding embedding = embeddingModel.embed(segment).content();
            embeddingStore.add(embedding, segment);
            count++;
        }
        
        return count;
    }
}
