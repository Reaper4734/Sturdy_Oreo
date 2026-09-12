-- ============================================================
-- Oreo AI Tutor: Schema Synchronization with JPA Entities (V7)
-- Adds missing tables and columns required by active JPA entities.
-- ============================================================

-- 1. Sync User entity fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS picture_url VARCHAR(500);
ALTER TABLE users ADD COLUMN IF NOT EXISTS domain VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS iq_logic VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS eq_resilience VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_points INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_streak INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_active_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS country VARCHAR(100);

-- 2. Sync Flashcard entity fields
ALTER TABLE flashcards ADD COLUMN IF NOT EXISTS album VARCHAR(255);
ALTER TABLE flashcards ADD COLUMN IF NOT EXISTS sub_album VARCHAR(255);

-- 3. Workspaces table (Required for Workspace entity and V6 foreign key)
CREATE TABLE IF NOT EXISTS workspaces (
    id VARCHAR(255) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    data JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workspaces_user ON workspaces(user_id);

-- 4. Learning Plans table (Required for LearningPlan entity and PlannerController)
CREATE TABLE IF NOT EXISTS learning_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    chat_thread_id UUID UNIQUE,
    goal_statement TEXT,
    plan_data JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_learning_plans_user ON learning_plans(user_id);

-- 5. Chat Threads table (Required for ChatThread entity and StreamingOrchestrationService)
CREATE TABLE IF NOT EXISTS chat_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    video_id VARCHAR(100),
    topic VARCHAR(100),
    title VARCHAR(255) NOT NULL DEFAULT 'New Conversation',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_threads_user ON chat_threads(user_id);

-- 6. Chat Messages table (Required for ChatMessageEntity and StreamingOrchestrationService)
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES chat_threads(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_thread ON chat_messages(thread_id);
