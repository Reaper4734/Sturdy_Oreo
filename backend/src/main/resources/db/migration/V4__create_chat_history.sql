-- V4__create_chat_history.sql

CREATE TABLE chat_history (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role            VARCHAR(10) NOT NULL, -- USER, ASSISTANT, SYSTEM
    text            TEXT NOT NULL,
    chat_mode       VARCHAR(20) NOT NULL DEFAULT 'INTERVIEW', -- INTERVIEW, MENTOR
    metadata        JSONB,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_session ON chat_history(session_id);
CREATE INDEX idx_chat_user ON chat_history(user_id);
