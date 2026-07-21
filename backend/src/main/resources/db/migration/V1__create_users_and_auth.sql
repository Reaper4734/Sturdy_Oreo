-- V1__create_users_and_auth.sql

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255),  -- Nullable for Google-only users
    display_name    VARCHAR(100) NOT NULL,
    auth_provider   VARCHAR(20) NOT NULL DEFAULT 'EMAIL', -- EMAIL, GOOGLE, BOTH
    google_id       VARCHAR(255) UNIQUE,
    current_phase   VARCHAR(20) NOT NULL DEFAULT 'INTERVIEW', -- INTERVIEW, REVEAL, EXECUTION
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_google_id ON users(google_id);
