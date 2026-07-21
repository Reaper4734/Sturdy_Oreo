-- V6__create_content_embeddings.sql

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE content_embeddings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id     VARCHAR(255) NOT NULL,
    chunk_index     INT NOT NULL,
    chunk_text      TEXT NOT NULL,
    embedding       vector(1536),
    metadata        JSONB NOT NULL,
    expires_at      TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_embeddings_doc ON content_embeddings(document_id);
