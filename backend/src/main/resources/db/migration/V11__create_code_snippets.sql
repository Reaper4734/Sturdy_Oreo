-- V11__create_code_snippets.sql

CREATE TABLE code_snippets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    node_id         VARCHAR(50) NOT NULL,
    language        VARCHAR(30) NOT NULL,
    code_content    TEXT NOT NULL,
    passed          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_code_user_node ON code_snippets(user_id, node_id);
