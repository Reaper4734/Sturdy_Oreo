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
      "chatTranscript": "I want to learn AWS Basics. I have 1 week. I am a beginner."
    }
    ```
    *(Note: If the frontend prefers to send a pre-summarized goal instead of the whole transcript, it will save 5 seconds of latency).*
*   **Response:** Returns the full `LearningPlan` object (including the nested JSONB `planData` tree with Milestones and Tasks).

### 1.2 Fetch Current Plan
*   **Endpoint:** `GET /api/orchestration/planner/`
*   **Purpose:** Loads the user's current plan for the Dashboard.
*   **Response:** Returns the full `LearningPlan` object. Returns 404 if no plan exists.

### 1.3 Mark Task Complete
*   **Endpoint:** `PUT /api/orchestration/planner/task/{taskId}/complete`
*   **Purpose:** Securely updates a single task's completion status and tracks the time spent.
*   **Request Body:**
    ```json
    {
      "actualTimeSpentMinutes": 20
    }
    ```
*   **Response:** Returns the updated `LearningPlan` object.

### 1.4 Adapt Plan (Remedial Injection)
*   **Endpoint:** `POST /api/orchestration/planner/adapt`
*   **Purpose:** Called when a user fails a quiz. Injects a `[Remedial]` task into the timeline instantly.
*   **Request Body:**
    ```json
    {
      "failedTaskId": "123e4567-e89b-12d3-a456-426614174000",
      "failedQuestion": "Explain constructor vs field dependency injection.",
      "userAnswer": "Field injection is faster and better."
    }
    ```
*   **Response:** Returns the updated `LearningPlan` object.

### 1.5 Reschedule Plan
*   **Endpoint:** `POST /api/orchestration/planner/reschedule`
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

## 🏁 Handover Checklist for Flutter Developer
- [ ] Ensure JWT token is injected into all API headers.
- [ ] Configure Dio / HTTP timeouts to 30000ms for `/generate` and `/evaluate` endpoints.
- [ ] Build the Dashboard UI to read the nested JSON tree inside `plan.planData.milestones`.
- [ ] Build the "Simulate 3 Days Inactivity" hidden Dev Button to trigger Nudge logic locally.
