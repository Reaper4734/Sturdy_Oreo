package com.oreo.engine.orchestration.controller;

import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.store.embedding.EmbeddingStore;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.util.HtmlUtils;

import java.nio.charset.StandardCharsets;
import java.util.Map;

@RestController
@RequestMapping("/api/orchestration")
public class RagController {

    private final EmbeddingStore<TextSegment> embeddingStore;
    private final EmbeddingModel embeddingModel;

    public RagController(EmbeddingStore<TextSegment> embeddingStore, EmbeddingModel embeddingModel) {
        this.embeddingStore = embeddingStore;
        this.embeddingModel = embeddingModel;
    }

    @PostMapping("/upload-document")
    public ResponseEntity<Map<String, String>> uploadDocument(@RequestParam("file") MultipartFile file) {
        try {
            // Read file content
            String rawContent = new String(file.getBytes(), StandardCharsets.UTF_8);
            
            // Sanitize content to prevent injection
            String sanitizedContent = HtmlUtils.htmlEscape(rawContent);

            // Simple chunking strategy (by newline)
            String[] chunks = sanitizedContent.split("\n\n");

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

            return ResponseEntity.ok(Map.of("message", "Successfully ingested " + count + " chunks into RAG."));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Failed to upload document: " + e.getMessage()));
        }
    }
}
