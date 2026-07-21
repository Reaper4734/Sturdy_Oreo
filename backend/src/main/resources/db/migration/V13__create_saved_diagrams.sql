-- V13__create_saved_diagrams.sql

CREATE TABLE saved_diagrams (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    node_id         VARCHAR(50) NOT NULL,
    title           VARCHAR(255) NOT NULL,
    payload_json    JSONB NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_diagrams_user ON saved_diagrams(user_id);
