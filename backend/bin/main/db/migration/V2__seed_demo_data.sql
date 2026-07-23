-- ============================================================
-- Oreo AI Tutor: Seed Demo Data Migration
-- Pre-populates the database with demo users, skill tree nodes,
-- flashcards, personas, and learning tracks for testing.
-- ============================================================

-- 1. Demo User
INSERT INTO users (id, email, password_hash, display_name, auth_provider, current_phase)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'alex.learner@oreo.ai',
    '$2a$10$wT8m9L4C4m.1o/aXfB3gEe1N9vB4u6uH8p9i0k1l2m3n4o5p6q7r8', -- bcrypt demo password
    'Alex Rivera',
    'EMAIL',
    'EXECUTION'
) ON CONFLICT (email) DO NOTHING;

-- 2. Learner Persona for Alex
INSERT INTO learner_personas (
    id, user_id, domain_topic, iq_logic, iq_visualization, iq_applied, iq_theoretical, eq_resilience, confidence_score, render_mode
) VALUES (
    'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Python & AI Engineering',
    75, 85, 80, 70, 90, 82, 'visual'
) ON CONFLICT (user_id) DO NOTHING;

-- 3. Skill Tree Nodes (Phase 2 Feature: Knowledge Skill Tree)
INSERT INTO skill_nodes (id, user_id, title, description, status, prerequisite_ids)
VALUES 
(
    'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380a01',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Python Syntax & Data Types',
    'Master variables, loops, conditionals, lists, and dictionaries.',
    'COMPLETED',
    ''
),
(
    'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a02',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Object-Oriented Programming (OOP)',
    'Classes, __init__ constructor, self, inheritance, and polymorphism.',
    'IN_PROGRESS',
    'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380a01'
),
(
    'c3eebc99-9c0b-4ef8-bb6d-6bb9bd380a03',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Vector Embeddings & RAG Search',
    'Understand pgvector, BM25 hybrid search, and LangChain4j integrations.',
    'LOCKED',
    'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a02'
) ON CONFLICT (id) DO NOTHING;

-- 4. Pre-Generated Flashcards (Phase 2 Feature: Spaced Repetition Anki-style)
INSERT INTO flashcards (id, user_id, front, back, next_review_date, interval_days, ease_factor, consecutive_correct_answers)
VALUES
(
    'd1eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'What does __init__ do in a Python class?',
    'It is the constructor method that automatically initializes an object instance attributes upon creation.',
    CURRENT_DATE + INTERVAL '1 day',
    1,
    2.5,
    1
),
(
    'd2eebc99-9c0b-4ef8-bb6d-6bb9bd380b02',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'What does the self keyword represent in Python methods?',
    'self refers to the specific instance of the object calling the method, allowing access to instance attributes.',
    CURRENT_DATE + INTERVAL '3 days',
    3,
    2.6,
    2
),
(
    'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380b03',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'What is Hybrid RAG Search?',
    'Combining pgvector semantic search with BM25 PostgreSQL text search for high precision retrieval.',
    CURRENT_DATE + INTERVAL '5 days',
    5,
    2.7,
    3
) ON CONFLICT (id) DO NOTHING;

-- 5. Learning Track (DAG)
INSERT INTO learning_tracks (id, user_id, goal, status, nodes, version)
VALUES (
    'e1eebc99-9c0b-4ef8-bb6d-6bb9bd380c01',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Become a Senior Python & AI Engineer',
    'ACCEPTED',
    '[
      {"id": "node-1", "title": "Python Fundamentals", "status": "COMPLETED"},
      {"id": "node-2", "title": "Object-Oriented Programming", "status": "IN_PROGRESS"},
      {"id": "node-3", "title": "pgvector & Hybrid RAG", "status": "PENDING"}
    ]'::jsonb,
    1
) ON CONFLICT (id) DO NOTHING;

-- 6. Sample Chat History
INSERT INTO chat_history (id, session_id, user_id, role, text, chat_mode, metadata)
VALUES (
    'f1eebc99-9c0b-4ef8-bb6d-6bb9bd380d01',
    'f2eebc99-9c0b-4ef8-bb6d-6bb9bd380d02',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'USER',
    'What is __init__ and self in Python classes?',
    'MENTOR',
    '{"topic": "Python OOP"}'::jsonb
) ON CONFLICT (id) DO NOTHING;
