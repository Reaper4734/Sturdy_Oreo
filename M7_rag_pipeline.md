# Module 7: RAG Pipeline — Implementation Specification

> **Tech Stack**: Java 21 · LangChain4j (Embedding + Retrieval) · PostgreSQL pgvector / Pinecone · Spring Boot
> **Reference**: [RAG MODULE.docx](file:///c:/CP/Oreo/RAG%20MODULE.docx) (all 4 sections)

---

## 1. Module Responsibility

This module is the **content supply chain**. It:
1. **Ingests** curated learning materials (YouTube transcripts, articles, documentation) and converts them into vector embeddings.
2. **Retrieves** the most relevant content for a given track node, filtered by topic and learner modality preference.
3. **Grounds** the AI Mentor (M6) by providing the transcript of the content the student is currently consuming, so the LLM answers in context rather than generically.
4. **Generates** quiz questions from specific material (consumed by M6's Closed-Loop Evaluator).

---

## 2. Project Structure

```
src/main/java/com/oreo/engine/rag/
├── RagService.java                        # Public facade — M5 and M6 call this
│
├── ingestion/
│   ├── IngestionService.java              # Orchestrates the full ingestion pipeline
│   ├── TranscriptFetcher.java             # Fetches YouTube transcripts (via API or scraper)
│   ├── ArticleFetcher.java                # Fetches and cleans article text from URLs
│   ├── TextChunker.java                   # Splits long documents into overlapping chunks
│   └── EmbeddingService.java              # Calls embedding model to convert text → vectors
│
├── retrieval/
│   ├── ContentRetriever.java              # Queries vector DB with topic + modality filters
│   └── MetadataFilter.java                # Builds filter expressions for modality, topic, type
│
├── storage/
│   ├── VectorStoreAdapter.java            # Interface for vector DB operations (store, query)
│   ├── PgVectorStore.java                 # PostgreSQL pgvector implementation
│   └── PineconeStore.java                 # Pinecone implementation (alternative)
│
├── model/
│   ├── ContentDocument.java               # { documentId, text, metadata, embedding[] }
│   ├── ContentMetadata.java               # { topic, modality, sourceUrl, contentType, estimatedMinutes }
│   ├── RetrievalQuery.java                # { topic, preferredModality, topK }
│   └── RetrievalResult.java               # { contentType, sourceUrl, transcript, estimatedMinutes, score }
│
├── discovery/                                 # NEW — Live Content Fetching (Hybrid RAG)
│   ├── ContentDiscoveryService.java        # Orchestrates: search → fetch → quality check → embed → cache
│   ├── YouTubeSearchClient.java            # YouTube Data API v3 search + transcript fetch
│   ├── WebSearchClient.java                # Google Custom Search API for articles/docs
│   ├── TranscriptQualityFilter.java        # Scores transcript reliability, rejects garbled auto-captions
│   └── DiscoveryRateLimiter.java           # Semaphore + dedup cache to protect API quotas
│
└── config/
    ├── RagConfig.java                     # Embedding model name, chunk size, overlap, vector dimensions
    └── VectorStoreConfig.java             # Connection details for pgvector or Pinecone
```

---

## 3. Vector Store Decision

Two options, both fully supported:

| Option | Pros | Cons | When to Use |
| :--- | :--- | :--- | :--- |
| **PostgreSQL + pgvector** | No additional infra — lives in the same PostgreSQL. | Slightly slower for 100K+ docs. | Default choice. Keeps stack simple. Acts as a **growing cache** that self-populates from live discovery. |
| **Pinecone** | Managed service, optimized for vector search. | External dependency, API key, network latency. | Only if content corpus exceeds 100K+ documents. |

The `VectorStoreAdapter` interface abstracts the implementation. Switching is a config change, not a code rewrite.

---

## 4. Ingestion Pipeline (One-Time / Admin Setup)

### 4a. What Gets Ingested

For each learning subject (e.g., "React 101"), curate:
- **10-15 YouTube video links** (with transcripts)
- **10-15 high-quality articles** (blog posts, official docs, tutorials)

These are manually curated for quality. The system does NOT crawl the open web.

### 4b. Ingestion Flow

```
Step 1: Admin provides a manifest JSON:
        [
          { "url": "https://youtube.com/watch?v=...", "type": "video", "topic": "react_state" },
          { "url": "https://react.dev/learn/state", "type": "article", "topic": "react_state" }
        ]
         ↓
Step 2: IngestionService iterates through each item:

        For videos:
          → TranscriptFetcher downloads the YouTube transcript (using YouTube Transcript API or
            a lightweight scraper service)
          → Result: raw transcript text + video metadata (title, duration)

        For articles:
          → ArticleFetcher fetches the page HTML, strips navigation/ads,
            extracts clean body text (using JSoup for Java HTML parsing)
          → Result: clean article text + metadata (title, word count)
         ↓
Step 3: TextChunker splits each document into overlapping chunks:
        - Chunk size: 500 tokens
        - Overlap: 100 tokens
        - Why overlap: Ensures context is not lost at chunk boundaries.
          A question about a concept that spans two chunks will still match.
         ↓
Step 4: EmbeddingService converts each chunk to a vector:
        - Model: text-embedding-3-small (OpenAI) or text-embedding-004 (Google)
        - Input: chunk text
        - Output: float[] of 1536 dimensions (OpenAI) or 768 (Google)
        - LangChain4j handles the API call and batching
         ↓
Step 5: VectorStoreAdapter stores the chunk + embedding + metadata:
        {
          "documentId": "yt_react_state_chunk_003",
          "text": "In React, state is how we remember things between renders...",
          "embedding": [0.0234, -0.1876, ...],
          "metadata": {
            "topic": "react_state",
            "modality": "video",
            "sourceUrl": "https://youtube.com/watch?v=...",
            "contentType": "video",
            "estimatedMinutes": 12,
            "chunkIndex": 3,
            "parentDocumentId": "yt_react_state"
          }
        }
```

### 4c. pgvector Table Schema

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE content_embeddings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id     VARCHAR(255) NOT NULL,
    chunk_text      TEXT NOT NULL,
    embedding       vector(1536),          -- or 768 for Google embeddings
    metadata        JSONB NOT NULL,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX ON content_embeddings USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);
```

---

## 5. Hybrid Content Retrieval (Runtime)

The system covers **all of CS** — Java, Python, ML, OS, Networking, etc. It's impossible to pre-ingest content for every topic. Instead, retrieval operates in **3 tiers**:

```
Tier 1: pgvector Cache   → Check for previously cached content (instant)
Tier 2: Live Discovery   → Search YouTube + Web APIs, fetch + embed on-demand (2-3 sec)
Tier 3: LLM Fallback     → AI Mentor answers from native knowledge (no external content)
```

### 5a. Retrieval Flow (Hybrid)

```
Step 1: M5 calls RagService.retrieveContent(nodeId, userPersona):
        - nodeId resolves to topic: "rust_ownership"
        - userPersona.renderMode resolves to preferredModality: "video"
         ↓
Step 2: TIER 1 — Check pgvector cache:
        - EmbeddingService converts topic to query vector
        - VectorStoreAdapter.query() searches cached embeddings
        - If similarity > 0.85: CACHE HIT → skip to Step 6
        - If similarity < 0.85 or no results: CACHE MISS → proceed to Step 3
         ↓
Step 3: TIER 2 — Live Content Discovery:
        - DiscoveryRateLimiter checks: is this topic already being fetched?
          → If yes (dedup): wait for the in-flight request to finish, use its results
          → If no: proceed
        - YouTubeSearchClient.search("rust ownership tutorial", modality: "video")
          → Returns top 3 video URLs + transcripts
        - WebSearchClient.search("rust ownership tutorial")
          → Returns top 3 article URLs + cleaned text
         ↓
Step 4: Quality Filter (L6 Fix):
        - TranscriptQualityFilter scores each fetched transcript (see 5c below)
        - Rejects garbled auto-captions (score < 0.5)
        - Prefers manually-captioned videos
         ↓
Step 5: Embed & Cache:
        - TextChunker splits each document into overlapping chunks (500 tokens, 100 overlap)
        - EmbeddingService converts chunks to vectors
        - VectorStoreAdapter.store() saves to pgvector
        - Next student asking for the same topic gets CACHE HIT instantly
         ↓
Step 6: Build RetrievalResult:
        {
          "contentType": "video",
          "sourceUrl": "https://www.youtube.com/embed/dGcsHMXbSOA",
          "transcript": "In Rust, ownership is the system that manages memory...",
          "estimatedMinutes": 12,
          "similarityScore": 0.92,
          "source": "cache" | "live_discovery"
        }
         ↓
Step 7: M5 returns this to the Flutter client
        - M3 renders the video player (or article reader)
        - M5 stores the transcript in session context for M6 to use
        - If source == "live_discovery": client shows brief "Curating your resources..." state
          during Steps 3-5 (2-3 seconds), then content loads
```

### 5b. Modality Fallback

If no content matches the preferred modality (e.g., no video exists for a niche topic):
1. Retry without the modality filter.
2. Return the best match regardless of type.
3. Attach a `"modality_mismatch": true` flag so the frontend can adjust the UI.
4. **Tier 3 fallback**: If live discovery also returns nothing useful, the AI Mentor operates on LLM native knowledge alone. The student gets chat + canvas explanations (which don't need external content) while the system continues searching in the background.

### 5c. Transcript Quality Filter (L6 Fix)

`TranscriptQualityFilter` scores transcripts before embedding:

| Check | Score Impact | Rationale |
| :--- | :--- | :--- |
| Transcript source = manual captions | +0.3 | Manual captions are accurate |
| Transcript source = auto-generated | -0.2 | Auto-captions mangle code terms |
| Contains recognized tech terms (useState, async, HashMap) | +0.2 | Indicates correct transcription of technical content |
| High ratio of non-dictionary words | -0.3 | Garbled auto-captions produce gibberish |
| Transcript length < 200 chars for a 10+ min video | -0.5 | Too sparse to be useful |

**Threshold**: If score < 0.5, reject the transcript. Use video title + description as lightweight grounding instead.

### 5d. Rate Limiter & Dedup (L9 Fix)

`DiscoveryRateLimiter` protects external API quotas:

| Protection | Implementation |
| :--- | :--- |
| **Concurrency cap** | `Semaphore(5)` — max 5 live discovery requests at a time |
| **Deduplication cache** | `ConcurrentHashMap<String, CompletableFuture<List<Content>>>` — if topic "python_basics" is already being fetched, the second request waits for the first and reuses results |
| **Cooldown** | After fetching for a topic, cache the result for 24 hours before allowing a re-fetch |
| **Quota tracking** | Log daily API call counts. If YouTube quota nears 80%, switch to Tier 3 (LLM-only) for the rest of the day |

### 5e. Content Staleness & Dead Link Checking (L12 Fix)

To prevent serving deleted YouTube videos or 404 article URLs:
- **HTTP HEAD Validation**: Before serving cached content from pgvector, M7 executes a fast HTTP HEAD request to `sourceUrl` (500ms timeout).
- If the URL returns 404 or 410 (Gone):
  1. Purge the dead document vectors from `content_embeddings`.
  2. Trigger fresh live discovery for the topic.
  3. Serve cached transcript text as a fallback article with notice: *"Original video unavailable; transcript text provided."*
- **Cache TTL**: Vector entries have an `expires_at` column (default 7 days). After 7 days, entry is re-validated on next query.

### 5f. Embedding Model Provider Alignment (L15 Fix)

To eliminate semantic misalignment between embeddings and LLM reasoning:
- When using **Gemini LLM**, use Google `text-embedding-004` (768 dimensions).
- When using **OpenAI LLM**, use OpenAI `text-embedding-3-small` (1536 dimensions).
- Managed via `RagConfig` based on active primary LLM provider.

---

## 6. Transcript Grounding (The Sidekick Context)

This is the critical differentiator from a generic chatbot. When the student asks a question in the Mentor Chat (M4), M6 needs the transcript of what the student is currently studying.

### How It Works

```
Step 1: Student asks: "I don't get what he meant at 2:15"
         ↓
Step 2: M5 receives the chat message with context: { videoTimestamp: 135 }
         ↓
Step 3: M5 calls RagService.getTranscriptContext(sessionId):
        - Returns the full transcript that was stored when the content was loaded (Step 7 above)
        - Optionally, narrows to a time window around 2:15 (±30 seconds) if timestamp-indexed
         ↓
Step 4: M5 passes the transcript to M6 (AI Orchestration) as part of the prompt context
         ↓
Step 5: M6's Sandbox Explainer pipeline inserts the transcript into the system prompt:
        "The user is watching a video with this transcript: [Insert Transcript].
         Answer their question using ONLY the concepts in this video."
         ↓
Step 6: LLM answers in context — not a generic Wikipedia-level answer,
        but specific to the material the student is struggling with
```

---

## 7. Quiz Content Provision

When M6's Closed-Loop Evaluator needs to generate a quiz (Feedback Gate):

```
Step 1: M6 calls RagService.getNodeTranscript(nodeId)
         ↓
Step 2: RagService looks up all chunks for the node's topic from the vector store
        and concatenates them into a coherent transcript (ordered by chunkIndex)
         ↓
Step 3: M6 injects the transcript into the quiz generation prompt:
        "Generate one practical, multiple-choice question to test
         the user's understanding of this specific text: [transcript]"
         ↓
Step 4: LLM generates a contextual quiz question
```

---

## 8. Integration Points

| Touches Module | How |
| :--- | :--- |
| **M5 (Java Core Engine)** | M5 calls `RagService.retrieveContent()` when a student opens a track node. M5 stores the transcript in session context and forwards it to M6 when needed. |
| **M6 (AI Orchestration)** | M6 calls `RagService.getTranscriptContext()` and `RagService.getNodeTranscript()` to ground prompts. M6 never queries the vector DB directly — it goes through M7's facade. |
| **M8 (PostgreSQL)** | If using pgvector, M7 stores and queries embeddings in the same PostgreSQL instance. The `content_embeddings` table is managed by M7. |
| **M3 (Video Player)** | M3 consumes the `sourceUrl` and `estimatedMinutes` returned by M7 (via M5). M3 does not interact with M7 directly. |
