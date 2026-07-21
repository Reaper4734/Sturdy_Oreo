-- V8__create_watch_progress.sql

CREATE TABLE watch_progress (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    node_id         VARCHAR(50) NOT NULL,
    content_url     TEXT NOT NULL,
    last_position   INT NOT NULL DEFAULT 0,
    total_duration  INT NOT NULL,
    percent_complete DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, node_id)
);

CREATE INDEX idx_watch_user_node ON watch_progress(user_id, node_id);
