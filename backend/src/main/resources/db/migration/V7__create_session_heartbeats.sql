-- V7__create_session_heartbeats.sql

CREATE TABLE session_heartbeats (
    user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    last_activity       TIMESTAMP NOT NULL DEFAULT NOW(),
    intervention_level  INT NOT NULL DEFAULT 0,
    session_paused      BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW()
);
