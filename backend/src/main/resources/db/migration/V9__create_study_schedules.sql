-- V9__create_study_schedules.sql

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
