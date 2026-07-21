-- V2__create_personas.sql

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
    render_mode         VARCHAR(20) NOT NULL DEFAULT 'visual', -- visual, textual, balanced
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX idx_personas_user ON learner_personas(user_id);
