-- V10__create_spaced_repetition_log.sql

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
