ALTER TABLE learning_tracks 
ADD COLUMN course_title VARCHAR(255),
ADD COLUMN difficulty VARCHAR(50),
ADD COLUMN estimated_hours INTEGER,
ADD COLUMN graph_type VARCHAR(50) DEFAULT 'DAG',
ADD COLUMN edges JSONB;
