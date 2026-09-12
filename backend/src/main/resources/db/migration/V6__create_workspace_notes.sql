-- V6__create_workspace_notes.sql
-- Creates relational schema for AFFiNE-inspired workspace notes and block-based pages

CREATE TABLE IF NOT EXISTS workspace_note_pages (
    id VARCHAR(255) PRIMARY KEY,
    workspace_id VARCHAR(255) NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL DEFAULT 'Untitled',
    parent_page_id VARCHAR(255) REFERENCES workspace_note_pages(id) ON DELETE CASCADE,
    icon VARCHAR(50),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS workspace_note_blocks (
    id VARCHAR(255) PRIMARY KEY,
    page_id VARCHAR(255) NOT NULL REFERENCES workspace_note_pages(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    content TEXT DEFAULT '',
    metadata JSONB,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_note_pages_workspace ON workspace_note_pages(workspace_id);
CREATE INDEX IF NOT EXISTS idx_note_pages_parent ON workspace_note_pages(parent_page_id);
CREATE INDEX IF NOT EXISTS idx_note_blocks_page ON workspace_note_blocks(page_id);
