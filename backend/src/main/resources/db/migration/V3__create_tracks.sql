-- V3__create_tracks.sql

CREATE TABLE learning_tracks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal            TEXT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PROPOSED', -- PROPOSED, ACCEPTED, ARCHIVED
    nodes           JSONB NOT NULL,
    version         INT NOT NULL DEFAULT 1, -- Optimistic locking
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tracks_user ON learning_tracks(user_id);
