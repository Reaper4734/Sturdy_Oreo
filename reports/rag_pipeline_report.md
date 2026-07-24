# Technical Audit Report: RAG Pipeline & Vector Database Integration

**Target Component**: RAG (Retrieval-Augmented Generation) & Content Ingestion Engine  
**Module Reference**: `com.oreo.engine.orchestration.rag` / `com.oreo.engine.orchestration.pipelines.RagIngestionPipeline`  
**Reviewer Role**: Senior Code Reviewer & System Architect  
**Audit Date**: July 24, 2026  
**Status**: **FIXED & VERIFIED** (100% Test Pass Rate)

---

## Executive Summary

The **Oreo Platform** RAG subsystem combines dense vector embeddings with classical keyword retrieval via a PostgreSQL `pgvector` store and standard Spring JDBC templates. The implementation utilizes LangChain4j (`0.36.2`) alongside the `AllMiniLmL6V2EmbeddingModel` (384 dimensions) for local semantic vector generation.

---

## Detailed Architectural Analysis

### 1. Vector Database Schema & Embedding Model
- **Embedding Model**: `dev.langchain4j.model.embedding.onnx.allminilml6v2.AllMiniLmL6V2EmbeddingModel`
- **Vector Store**: `PgVectorEmbeddingStore` targeting table `document_embeddings` with 384 dimensions.
- **pgvector Integration**: Clean connection parameter extraction (`host`, `port`, `database`, `user`, `password`) from JDBC URL in `RagConfig.java`.

### 2. Hybrid Retrieval Mechanism (`HybridRetriever.java`)
- **Formula**:
  $$\text{Final Score} = (\text{Cosine Similarity}) \times 0.7 + (\text{BM25 } \texttt{ts\_rank}) \times 0.3$$
- **SQL Implementation**:
  ```sql
  SELECT content, 
         (1 - (embedding <=> ?::vector)) AS vector_score,
         ts_rank(to_tsvector('english', content), plainto_tsquery('english', ?)) AS keyword_score
  FROM document_embeddings
  ORDER BY ( (1 - (embedding <=> ?::vector)) * 0.7 + ts_rank(to_tsvector('english', content), plainto_tsquery('english', ?)) * 0.3 ) DESC
  LIMIT 5
  ```
- **Evaluation**: Dual-scoring approach outperforms raw vector similarity for domain-specific technical queries containing exact symbols or function names.

---

## Data Paraphrasing & Character Corruption Audit (RESOLVED)

> [!NOTE]
> **RESOLVED: Data Paraphrasing / Character Corruption Fix in `RagIngestionPipeline.java`**:
> - **Previous Code**:
>   ```java
>   String rawContent = new String(file.getBytes(), StandardCharsets.UTF_8);
>   String sanitizedContent = HtmlUtils.htmlEscape(rawContent);
>   String[] chunks = sanitizedContent.split("\n\n");
>   ```
> - **Applied Fix**:
>   ```java
>   String rawContent = new String(file.getBytes(), StandardCharsets.UTF_8);
>   String[] chunks = rawContent.split("\n\n");
>   ```
> - **Result**: `HtmlUtils.htmlEscape` has been removed from embedding text preprocessing. Document bytes are stored in `document_embeddings` with 100% exact semantic fidelity. Code symbols (`<`, `>`, `&`, `"`) remain unescaped, maximizing vector similarity search accuracy.

---

## Test Cases & Verification Results

| Test ID | Test Description | Target Method | Status | Findings / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `TC-RAG-01` | Double-newline chunking verification | `RagIngestionPipeline.ingestDocument` | **PASS** | Successfully splits non-empty paragraphs into distinct text segments. |
| `TC-RAG-02` | Whitespace-only chunk filtration | `RagIngestionPipeline.ingestDocument` | **PASS** | Ignores blank lines and empty blocks. |
| `TC-RAG-03` | Metadata filename assignment | `RagIngestionPipeline.ingestDocument` | **PASS** | Attaches `filename` metadata attribute to each `TextSegment`. |
| `TC-RAG-04` | Raw text symbol preservation | `RagIngestionPipeline.ingestDocument` | **PASS** | Verified that raw symbols (`x < y & a > b`) are preserved without HTML escaping. |
| `TC-RAG-05` | Hybrid retrieval SQL formatting | `HybridRetriever.retrieve` | **PASS** | Converts embedding vector to `[v1, v2, ...]` literal and executes combined vector+BM25 query. |
