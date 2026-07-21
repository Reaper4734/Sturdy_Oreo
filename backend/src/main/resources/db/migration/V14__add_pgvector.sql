CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE document_embeddings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    content text NOT NULL,
    metadata jsonb,
    embedding vector(768) -- Google Gemini text-embedding-004 uses 768 dimensions by default
);

-- Index for fast cosine similarity search
CREATE INDEX document_embeddings_embedding_idx ON document_embeddings USING hnsw (embedding vector_cosine_ops);
