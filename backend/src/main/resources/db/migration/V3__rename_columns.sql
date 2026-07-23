-- Fix columns for LangChain4j PgVectorEmbeddingStore defaults
ALTER TABLE document_embeddings RENAME COLUMN id TO embedding_id;
ALTER TABLE document_embeddings RENAME COLUMN content TO text;
