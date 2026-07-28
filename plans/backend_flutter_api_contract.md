# Oreo Backend -> Flutter API Contract

This document outlines the exact endpoints, required payloads, and expected behaviors the Flutter app must implement to seamlessly integrate with the Spring Boot Agentic Backend.

## ⚠️ Core Frontend Guardrails
Before implementing any API calls, the Flutter team **must** adhere to these rules:
1. **The 30-Second Rule:** Any endpoint tagged with `[AI-Agent]` takes 10-20 seconds to resolve. The Flutter `http` timeout MUST be explicitly set to 30 seconds for these calls.
2. **Loading States:** During `[AI-Agent]` calls, the UI MUST display a full-screen, non-dismissible loading overlay (e.g., *"Agent is constructing your syllabus..."*).
3. **Authentication:** All requests must include the JWT token in the `Authorization: Bearer <token>` header.

---

## 1. Plan Generation & Execution

### 1.1 Generate Dynamic Plan `[AI-Agent]`
*   **Endpoint:** `POST /api/orchestration/planner/generate`
*   **Purpose:** Triggers the Gemini Agent and YouTube Search Tool to build the JSONB syllabus.
*   **Request Body:**
    ```json
    {
      "chatTranscript": "I want to learn AWS Basics...",
      "chatThreadId": "abc-123-xyz"
    }
    ```
    *(Note: If the frontend prefers to send a pre-summarized goal instead of the whole transcript, it will save 5 seconds of latency).*
*   **Response:** Returns `HTTP 202 Accepted` immediately with `{ "status": "processing" }`.
*   **WebSocket Delivery:** The frontend MUST subscribe to `/topic/session/user/{userId}/plan`. The full `LearningPlan` JSON will be pushed there when 3.1 Flash Lite finishes generating it.

### 1.2 Fetch Current Plan
*   **Endpoint:** `GET /api/orchestration/planner/{chatThreadId}`
*   **Purpose:** Loads the user's current plan for the Dashboard.
*   **Response:** Returns the full `LearningPlan` object. Returns 404 if no plan exists.

### 1.3 Mark Task Complete
*   **Endpoint:** `PUT /api/orchestration/planner/{chatThreadId}/task/{taskId}/complete`
*   **Purpose:** Securely updates a single task's completion status and tracks the time spent.
*   **Request Body:**
    ```json
    {
      "actualTimeSpentMinutes": 20
    }
    ```
*   **Response:** Returns the updated `LearningPlan` object.

### 1.4 Adapt Plan (Remedial Injection)
*   **Endpoint:** `POST /api/orchestration/planner/{chatThreadId}/adapt`
*   **Purpose:** Called when a user fails a quiz. Injects a `[Remedial]` task into the timeline instantly.
*   **Request Body:**
    ```json
    {
      "failedTaskId": "123e4567-e89b-12d3-a456-426614174000",
      "failedQuestion": "Explain constructor vs field dependency injection.",
      "userAnswer": "Field injection is faster and better."
    }
    ```
*   **Response:** Returns `HTTP 202 Accepted`.
*   **WebSocket Delivery:** The frontend MUST subscribe to `/topic/session/user/{userId}/plan`. The updated `LearningPlan` JSON (with the injected task) will be pushed there.

### 1.5 Reschedule Plan
*   **Endpoint:** `POST /api/orchestration/planner/{chatThreadId}/reschedule`
*   **Purpose:** Shifts all incomplete task deadlines forward by 2 days if the user falls behind.
*   **Request Body:** None (Empty POST).
*   **Response:** Returns the updated `LearningPlan` object.

---

## 2. Active Feedback Loop (Assessments)

### 2.1 Generate Quiz `[AI-Agent]`
*   **Endpoint:** `POST /api/orchestration/assessments/generate`
*   **Purpose:** Generates a stateless, on-the-fly quiz (3 MCQs, 2 Subjectives) based on a topic.
*   **Request Body:**
    ```json
    {
      "topic": "AWS IAM Policies"
    }
    ```
*   **Response:** Returns an `AssessmentPayload` containing the questions.
    ```json
    {
      "multipleChoiceQuestions": [
        {
          "question": "What is IAM?",
          "options": ["Identity", "Internet"],
          "correctAnswer": "Identity",
          "explanation": "IAM stands for Identity and Access Management."
        }
      ],
      "subjectiveQuestions": [ ... ]
    }
    ```

### 2.2 Grade Subjective Answer `[AI-Agent]`
*   **Endpoint:** `POST /api/orchestration/assessments/evaluate`
*   **Purpose:** Sends the user's typed answer to the AI for strict grading.
*   **Request Body:**
    ```json
    {
      "question": "Explain what an IAM Policy is.",
      "userAnswer": "It is a rule that tells AWS who can do what."
    }
    ```
*   **Response:**
    ```json
    {
      "score": 65,
      "feedback": "Good basic understanding, but lacks technical depth regarding JSON structure.",
      "passed": true
    }
    ```
    *(Rule: If `passed: false`, Flutter should prompt the user to review the material).*

---

## 3. Gamification

### 3.1 Award Points
*   **Endpoint:** `POST /api/orchestration/gamification/award`
*   **Purpose:** Awards points for completing a task and automatically bumps the user's daily streak.
*   **Request Body:**
    ```json
    {
      "points": 50
    }
    ```
*   **Response:** 
    ```json
    {
      "totalPoints": 450,
      "currentStreak": 3,
      "message": "Awarded 50 points"
    }
    ```

---

## 4. Auth & Profiles

*   **Google Login:** `POST /api/auth/google/verify` -> Expects `{ "idToken": "..." }`. Returns JWT.
*   **Fetch Profile:** `GET /api/auth/profile` -> Returns `User` object (including `totalPoints`, `currentStreak`, etc.).

---

## 5. Spaced Repetition (Flashcards)

### 5.1 Fetch Due Flashcards
*   **Endpoint:** `GET /api/orchestration/flashcards`
*   **Purpose:** Retrieves all flashcards for the user. (Frontend should filter by `nextReviewDate <= today` to show only due cards).
*   **Response:** Returns a JSON Array of `Flashcard` objects.

### 5.2 Generate Flashcards `[AI-Agent]`
*   **Endpoint:** `POST /api/orchestration/flashcards/generate`
*   **Purpose:** AI reads a transcript or topic and automatically generates a deck of study cards.
*   **Request Body:**
    ```json
    {
      "transcript": "Explain the difference between final and effectively final in Java."
    }
    ```
*   **Response:** Returns the generated list of `Flashcard` objects.

### 5.3 Review Flashcard (SuperMemo-2)
*   **Endpoint:** `POST /api/orchestration/flashcards/review`
*   **Purpose:** Submits the user's recall quality (0 to 5) to calculate the next review date via the SM-2 algorithm.
*   **Request Body:**
    ```json
    {
      "cardId": "uuid-here",
      "quality": 4
    }
    ```
    *(0 = Blackout, 3 = Hard, 4 = Good, 5 = Perfect).*

---

## 6. Watchdog & Idle Nudging (WebSockets)

To support the real-time "Nudge" feature when a user abandons the app:

### 6.1 Connect & Heartbeat
*   **Connection URL:** `ws://<backend_url>/ws/orchestration`
*   **Heartbeat Action:** The Flutter app must send a heartbeat every 60 seconds to `SEND /app/session/heartbeat` with payload `{ "sessionId": "user123" }`.

### 6.2 Receive Interventions
*   **Subscription Topic:** `SUBSCRIBE /topic/session/user/{userId}/interventions`
*   **Action:** If the user stops sending heartbeats for 3 minutes, the Watchdog Daemon triggers an LLM to generate a personalized motivational message. Flutter will receive a JSON payload here containing the `message` to display as a Push Notification.

### 6.3 Async Generation Queue (Latency Fix)
*   **Subscription Topic:** `SUBSCRIBE /topic/session/user/{userId}/plan`
*   **Action:** When Flutter calls `/generate` or `/adapt`, those HTTP requests return instantly. The frontend must listen to this WebSocket topic to receive the massive JSON object when the AI finishes building the syllabus.

---

## 7. AI Canvas & Diagrams (Eraser & PenEcho Clones)

### 7.1 Generate Knowledge Graph / Diagram (Eraser Mode)
*   **Endpoint:** `POST /api/resource-map/generate`
*   **Purpose:** Builds a Mermaid diagram code for the canvas AND a structured JSON graph of external resources (GeeksForGeeks, W3Schools, etc.).
*   **Request Body:**
    ```json
    {
      "subject": "Build a real-time dashboard with React"
    }
    ```
*   **Response:** Returns a `ResourceMapSchema` containing the Mermaid diagram code and categorized branches.
    ```json
    {
      "subject": "React Dashboard",
      "mermaidGraph": "graph TD\\n  [React Basics] --> (State Management)...",
      "branches": [
        {
          "topic": "React Basics",
          "authoritativeResource": { "url": "https://geeksforgeeks.org/..." }
        }
      ]
    }
    ```

### 7.2 AI Canvas / Video Explanation (PenEcho Mode)
*   **Endpoint:** `POST /api/orchestration/canvas-explain`
*   **Purpose:** AI reads a specific doubt or context (from the canvas or video timestamp) and explains it.
*   **Request Body:**
    ```json
    {
      "doubt": "Why do we need a WebSocket here instead of HTTP?",
      "difficultyLevel": 3,
      "videoTimestamp": 10.5,
      "videoId": "dQw4w9WgXcQ",
      "sessionId": "11111111-1111-1111-1111-111111111111",
      "language": "en"
    }
    ```
*   **Response:** Returns a JSON object containing the AI's explanation.
    ```json
    {
      "explanation": "WebSockets maintain a persistent connection..."
    }
    ```

---

## 8. Onboarding & RAG Ingestion

### 8.1 Dynamic Profiler (Interview)
*   **Endpoint:** `POST /api/orchestration/interview`
*   **Purpose:** Chat-based onboarding to determine the user's skill level and goals.
*   **Request Body:**
    ```json
    {
      "message": "I want to learn Spring Boot",
      "history": "User knows basic Java."
    }
    ```
*   **Response:** Returns a `ProfilerOutputSchema`.

### 8.1.1 Save User Persona (Complete Interview)
*   **Endpoint:** `POST /api/orchestration/interview/complete`
*   **Purpose:** Permanently saves the user's profiled traits to their database account.
*   **Request Body:**
    ```json
    {
      "domain": "Software Engineering",
      "iqLogic": "Visual Learner",
      "eqResilience": "Needs early wins"
    }
    ```
*   **Response:** `200 OK` with success message.

### 8.2 RAG Document Upload
*   **Endpoint:** `POST /api/orchestration/upload-document`
*   **Purpose:** Upload a PDF or Text file to add custom knowledge to the RAG database.
*   **Request Format:** `multipart/form-data` with a file field named `file`.
*   **Response:** Returns `{ "message": "Successfully ingested X chunks into RAG." }`

---

## 9. Coding Dojo (Interactive Code Challenges)

### 9.1 Generate Video Challenge
*   **Endpoint:** `POST /api/orchestration/challenge/generate`
*   **Purpose:** Triggers the AI to watch a YouTube video timestamp and create a programming challenge based on the exact concept being taught.
*   **Request Body:**
    ```json
    {
      "videoId": "dQw4w9WgXcQ",
      "videoTimestamp": 45.5,
      "doubtContext": "I want to practice concepts taught here.",
      "language": "Python"
    }
    ```
*   **Response:** Returns an `ExtractedChallenge` JSON containing the problem statement and constraints.

### 9.2 Grade Code Submission
*   **Endpoint:** `POST /api/orchestration/challenge/grade`
*   **Purpose:** Sends the user's IDE code to the backend for strict AI grading and feedback.
*   **Request Body:**
    ```json
    {
      "problemStatement": "Write a function to...",
      "language": "Python",
      "code": "def my_func():..."
    }
    ```
*   **Response:** Returns a `GradingResult` with pass/fail status and feedback.

---

## 12. Video Ingestion

### 12.1 Trigger Background Ingestion
*   **Endpoint:** `POST /api/orchestration/ingest`
*   **Purpose:** Triggers the backend to fetch YouTube transcripts/metadata and begin seeding them into the AI knowledge base.
*   **Request Body:**
    ```json
    {
      "videoId": "pnWINBJ3-yA"
    }
    ```
*   **Response:** Returns `HTTP 202 Accepted` along with the WebSocket topic to subscribe to.
    ```json
    {
      "status": "Ingestion started",
      "videoId": "pnWINBJ3-yA",
      "topic": "/topic/ingestion/pnWINBJ3-yA"
    }
    ```
*   **WebSocket Delivery:** The frontend MUST subscribe to `/topic/ingestion/{videoId}` to stream live progress updates as the AI processes the video.

---

## 13. Chat Threads & History

### 13.1 Fetch All Chat Threads
*   **Endpoint:** `GET /api/orchestration/chats`
*   **Purpose:** Retrieves all historical chat conversations for the current user, sorted by creation date.
*   **Response:** Returns a JSON Array of `ChatThread` objects.

### 13.2 Create New Chat Thread
*   **Endpoint:** `POST /api/orchestration/chats`
*   **Purpose:** Initializes a new chat session linked to a specific video.
*   **Request Body:**
    ```json
    {
      "videoId": "pnWINBJ3-yA",
      "title": "Discussion on Spring Boot"
    }
    ```
*   **Response:** Returns the created `ChatThread` object.

### 13.3 Fetch Messages for Thread
*   **Endpoint:** `GET /api/orchestration/chats/{threadId}/messages`
*   **Purpose:** Retrieves all chat messages associated with a specific thread, sorted chronologically.
*   **Response:** Returns a JSON Array of `ChatMessageEntity` objects.

---

## 🏁 Handover Checklist for Flutter Developer
- [ ] Ensure JWT token is injected into all API headers.
- [ ] Configure Dio / HTTP timeouts to 30000ms for `/generate` and `/evaluate` endpoints.
- [ ] Build the Dashboard UI to read the nested JSON tree inside `plan.planData.milestones`.
- [ ] Implement a WebSocket client (e.g. `stomp_dart_client`) for heartbeats and nudges.
