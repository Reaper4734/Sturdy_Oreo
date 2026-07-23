-- Drop existing index, update dimension to 384 for AllMiniLmL6V2 ONNX model, and recreate index
DROP INDEX IF EXISTS document_embeddings_embedding_idx;
TRUNCATE TABLE document_embeddings;
ALTER TABLE document_embeddings ALTER COLUMN embedding TYPE vector(384);
CREATE INDEX document_embeddings_embedding_idx ON document_embeddings USING hnsw (embedding vector_cosine_ops);
