-- ============================================================
-- Oreo AI Tutor: Complete Database Schema
-- Single consolidated migration for a clean development setup.
-- ============================================================

-- =========================
-- 1. Core Auth & Users
-- =========================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255),
    display_name    VARCHAR(100) NOT NULL,
    auth_provider   VARCHAR(20) NOT NULL DEFAULT 'EMAIL',
    google_id       VARCHAR(255) UNIQUE,
    current_phase   VARCHAR(20) NOT NULL DEFAULT 'INTERVIEW',
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_google_id ON users(google_id);

-- =========================
-- 2. Learner Personas
-- =========================
CREATE TABLE learner_personas (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    domain_topic        VARCHAR(100) NOT NULL,
    iq_logic            INT NOT NULL DEFAULT 50,
    iq_visualization    INT NOT NULL DEFAULT 50,
    iq_applied          INT NOT NULL DEFAULT 50,
    iq_theoretical      INT NOT NULL DEFAULT 50,
    eq_resilience       INT NOT NULL DEFAULT 50,
    confidence_score    INT NOT NULL DEFAULT 0,
    render_mode         VARCHAR(20) NOT NULL DEFAULT 'visual',
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX idx_personas_user ON learner_personas(user_id);

-- =========================
-- 3. Learning Tracks (DAG)
-- =========================
CREATE TABLE learning_tracks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal            TEXT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PROPOSED',
    nodes           JSONB NOT NULL,
    version         INT NOT NULL DEFAULT 1,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tracks_user ON learning_tracks(user_id);

-- =========================
-- 4. Chat History
-- =========================
CREATE TABLE chat_history (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role            VARCHAR(10) NOT NULL,
    text            TEXT NOT NULL,
    chat_mode       VARCHAR(20) NOT NULL DEFAULT 'INTERVIEW',
    metadata        JSONB,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_session ON chat_history(session_id);
CREATE INDEX idx_chat_user ON chat_history(user_id);

-- =========================
-- 5. Activity Log
-- =========================
CREATE TABLE activity_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type      VARCHAR(50) NOT NULL,
    node_id         VARCHAR(50),
    data            JSONB,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_activity_user ON activity_log(user_id);
CREATE INDEX idx_activity_time ON activity_log(created_at);

-- =========================
-- 6. Vector Embeddings (pgvector)
-- =========================
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

CREATE TABLE document_embeddings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content         TEXT NOT NULL,
    metadata        JSONB,
    embedding       vector(768)
);

CREATE INDEX document_embeddings_embedding_idx ON document_embeddings USING hnsw (embedding vector_cosine_ops);

-- =========================
-- 7. Session Heartbeats (Watchdog)
-- =========================
CREATE TABLE session_heartbeats (
    user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    last_activity       TIMESTAMP NOT NULL DEFAULT NOW(),
    intervention_level  INT NOT NULL DEFAULT 0,
    session_paused      BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =========================
-- 8. Watch Progress
-- =========================
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

-- =========================
-- 9. Study Schedules
-- =========================
CREATE TABLE study_schedules (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_completion_date  DATE NOT NULL,
    daily_study_minutes     INT NOT NULL DEFAULT 45,
    schedule_data           JSONB NOT NULL,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_schedule_user ON study_schedules(user_id);

-- =========================
-- 10. Spaced Repetition Log
-- =========================
CREATE TABLE spaced_repetition_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    node_id         VARCHAR(50) NOT NULL,
    interval_days   INT NOT NULL,
    due_date        DATE NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    score           DECIMAL(3,2),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_spaced_due ON spaced_repetition_log(due_date, status);

-- =========================
-- 11. Code Snippets
-- =========================
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

-- =========================
-- 12. User Notes
-- =========================
CREATE TABLE user_notes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    node_id         VARCHAR(50) NOT NULL,
    markdown_text   TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, node_id)
);

CREATE INDEX idx_notes_user_node ON user_notes(user_id, node_id);

-- =========================
-- 13. Saved Diagrams
-- =========================
CREATE TABLE saved_diagrams (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    node_id         VARCHAR(50) NOT NULL,
    title           VARCHAR(255) NOT NULL,
    payload_json    JSONB NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_diagrams_user ON saved_diagrams(user_id);

-- =========================
-- 14. Flashcards (Phase 2 - Spaced Repetition)
-- =========================
CREATE TABLE flashcards (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID NOT NULL,
    front                       VARCHAR(1000) NOT NULL,
    back                        VARCHAR(2000) NOT NULL,
    next_review_date            DATE,
    interval_days               INTEGER NOT NULL DEFAULT 0,
    ease_factor                 REAL NOT NULL DEFAULT 2.5,
    consecutive_correct_answers INTEGER NOT NULL DEFAULT 0
);

-- =========================
-- 15. Skill Nodes (Phase 2 - Knowledge Tree)
-- =========================
CREATE TABLE skill_nodes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL,
    title               VARCHAR(255) NOT NULL,
    description         VARCHAR(1000),
    status              VARCHAR(50) NOT NULL,
    prerequisite_ids    TEXT
);
