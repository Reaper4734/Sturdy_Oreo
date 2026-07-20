# Module 5: Java Core Engine — Implementation Specification

> **Tech Stack**: Java 21 · Spring Boot 3.x · Spring WebSocket (STOMP) · Spring Security · PostgreSQL · Flyway
> **Reference**: [AGENTIC MODULE.docx](file:///c:/CP/Oreo/AGENTIC%20MODULE.docx) (Handoff Logic, DAG Mutation), [UI MODULE.docx](file:///c:/CP/Oreo/UI%20MODULE.docx) (Auth Flow), [RAG MODULE.docx](file:///c:/CP/Oreo/RAG%20MODULE.docx) (Content Fetch)

---

## 1. Module Responsibility

This is the **central nervous system** of the platform. It:
1. Authenticates users (Email/Password + Google OAuth2 + JWT).
2. Manages the session state machine (enforces phase transitions).
3. Stores and mutates the learning track DAG.
4. Runs the Watchdog background daemon.
5. Operates the WebSocket server (STOMP broker) for all real-time communication.
6. Routes requests to M6 (AI Orchestration) and M7 (RAG Pipeline).

Every request from the Flutter client passes through M5. It is the single gateway.

---

## 2. Project Structure (Spring Boot)

```
src/main/java/com/oreo/engine/
├── OreoApplication.java                       # Spring Boot entry point
│
├── config/
│   ├── SecurityConfig.java                    # JWT filter chain, OAuth2 client, CORS, CSRF
│   ├── WebSocketConfig.java                   # STOMP endpoint + message broker config
│   ├── DataSourceConfig.java                  # PostgreSQL connection pool (HikariCP)
│   └── SchedulingConfig.java                  # Enable @Scheduled for Watchdog
│
├── auth/
│   ├── controller/
│   │   └── AuthController.java                # POST /auth/register, POST /auth/login, POST /auth/google
│   ├── service/
│   │   ├── AuthService.java                   # Register, login, password validation
│   │   ├── GoogleAuthService.java             # Verify Google ID token, create/link user
│   │   └── JwtService.java                    # Issue + validate JWT tokens
│   ├── model/
│   │   ├── RegisterRequest.java               # { email, password, displayName }
│   │   ├── LoginRequest.java                  # { email, password }
│   │   ├── GoogleAuthRequest.java             # { idToken }
│   │   └── AuthResponse.java                  # { token, userId, isNewUser }
│   └── filter/
│       └── JwtAuthenticationFilter.java       # Intercepts requests, extracts JWT, sets SecurityContext
│
├── session/
│   ├── controller/
│   │   └── SessionController.java             # GET /api/session/state
│   ├── service/
│   │   └── SessionService.java                # Reads user phase, returns SessionState DTO
│   ├── model/
│   │   ├── SessionState.java                  # { userId, phase, trackAccepted, personaGenerated, activeNodeId }
│   │   └── UserPhase.java                     # Enum: ONBOARDING, CALIBRATION, EXECUTION
│   └── guard/
│       └── PhaseGuard.java                    # Validates phase transitions (no skipping ahead)
│
├── persona/
│   ├── controller/
│   │   └── PersonaController.java             # GET /api/persona/{userId}
│   ├── service/
│   │   └── PersonaService.java                # CRUD for LearnerPersona. Computes render_mode.
│   ├── model/
│   │   ├── LearnerPersona.java                # POJO with cognitiveProfile, traits, renderMode
│   │   └── CognitiveProfile.java              # { logic, visualization, applied, theoretical }
│   └── repository/
│       └── PersonaRepository.java             # Spring Data JPA → learner_personas table
│
├── track/
│   ├── controller/
│   │   └── TrackController.java               # POST /api/track/generate, POST /api/track/negotiate, GET /api/track/{userId}
│   ├── service/
│   │   ├── TrackService.java                  # CRUD for LearningTrack. Manages node status.
│   │   └── TrackMutationService.java          # Inserts remedial nodes, swaps modules, re-links prereqs
│   ├── model/
│   │   ├── LearningTrack.java                 # { trackId, goal, nodes[] }
│   │   ├── TrackNode.java                     # { id, title, type, status, prereqs[] }
│   │   └── NodeStatus.java                    # Enum: LOCKED, ACTIVE, COMPLETED
│   └── repository/
│       └── TrackRepository.java               # Spring Data JPA → learning_tracks table (JSONB)
│
├── content/
│   ├── controller/
│   │   └── ContentController.java             # GET /api/content/{nodeId}
│   ├── service/
│   │   └── ContentService.java                # Calls M7 (RAG) to fetch content for a node
│   └── model/
│       └── ContentItem.java                   # { contentType, sourceUrl, transcript, estimatedMinutes }
│
├── quiz/
│   ├── controller/
│   │   └── QuizController.java                # POST /api/quiz/generate, POST /api/quiz/submit, POST /api/quiz/intervention-submit
│   ├── service/
│   │   └── QuizService.java                   # Calls M6 to generate quiz, grades answers, triggers DAG mutation on fail
│   └── model/
│       ├── QuizPayload.java                   # { question, options[], correctAnswerIndex }
│       └── QuizResult.java                    # { status, feedback, action?, newNode? }
│
├── chat/
│   ├── controller/
│   │   ├── ChatRestController.java            # GET /api/chat/history/{sessionId}
│   │   └── ChatWebSocketController.java       # @MessageMapping for STOMP chat messages
│   ├── service/
│   │   └── ChatRoutingService.java            # Determines chat mode, attaches context, routes to M6
│   └── model/
│       ├── ChatIncoming.java                  # { text, context: { videoTimestamp, selectedCanvasNode, chatMode } }
│       ├── ChatResponse.java                  # { reply, internalState?, canvasPayload?, trackUpdate? }
│       └── ChatMessage.java                   # { id, sessionId, role, text, timestamp, metadata }
│
├── watchdog/
│   ├── service/
│   │   ├── WatchdogScheduler.java             # @Scheduled daemon: scans for idle sessions
│   │   ├── HeartbeatTracker.java              # In-memory map of last-activity timestamps per userId
│   │   └── InterventionDispatcher.java        # Generates + pushes micro-quiz or nudge via WebSocket
│   └── model/
│       └── InterventionPayload.java           # { quizQuestion, options[], source: "watchdog" }
│
├── activity/
│   ├── controller/
│   │   └── ActivityController.java            # POST /api/activity/heartbeat
│   ├── service/
│   │   └── ActivityService.java               # Logs events, updates HeartbeatTracker
│   └── model/
│       └── ActivityEvent.java                 # { userId, nodeId, event, data, timestamp }
│
└── common/
    ├── exception/
    │   ├── GlobalExceptionHandler.java        # @ControllerAdvice for consistent error responses
    │   └── PhaseViolationException.java       # Thrown when user tries to skip a phase
    └── dto/
        └── ApiResponse.java                   # Standard wrapper: { success, data, error }
```

---

## 3. Authentication System

Two login methods: **Email/Password** and **Google Sign-In**. Both produce the same JWT for downstream use.

### 3a. Email/Password Registration & Login

```
POST /auth/register { "email": "student@example.com", "password": "s3cur3P@ss", "displayName": "Alex" }
  → AuthService validates email format and password strength (min 8 chars, 1 uppercase, 1 number)
  → Checks if email already exists in users table
  → If new: hashes password with BCryptPasswordEncoder, creates user record
  → Sets user phase to ONBOARDING
  → JwtService issues JWT (HS256, 7-day expiry, contains userId + email)
  → Returns { "token": "eyJ...", "userId": "u_abc123", "isNewUser": true }
  → If email exists: Returns 409 Conflict

POST /auth/login { "email": "student@example.com", "password": "s3cur3P@ss" }
  → AuthService looks up user by email
  → Validates password hash with BCryptPasswordEncoder.matches()
  → If valid:
      → JwtService issues JWT
      → Returns { "token": "eyJ...", "userId": "u_abc123", "isNewUser": false }
  → If invalid: Returns 401 Unauthorized
```

### 3b. Google OAuth2 Sign-In

```
POST /auth/google { "idToken": "eyJhbGciOi..." }
  → GoogleAuthService verifies the ID token using Google's public keys
    (via google-auth-library-java: GoogleIdTokenVerifier)
  → Extracts: email, name, pictureUrl from the verified token payload
  → Checks if a user with this email already exists:
      → If exists with EMAIL auth: links Google account (sets auth_provider = "BOTH"), keeps password hash, issues JWT
      → If exists with GOOGLE auth: just logs in, issues JWT
      → If new: creates user with auth_provider = "GOOGLE", no password hash needed
  → Sets user phase to ONBOARDING (if new) or restores previous phase
  → JwtService issues JWT (HS256, 7-day expiry, contains userId + email)
  → Returns { "token": "eyJ...", "userId": "u_abc123", "isNewUser": true/false }
```

**Flutter-side**: Uses the `google_sign_in` package to launch the native Google consent screen. The package returns a Google ID Token, which the app sends to `POST /auth/google`. The backend never handles OAuth redirects — the client does all of it natively.

### 3c. JWT Security

- `JwtAuthenticationFilter` extends `OncePerRequestFilter`.
- Extracts the `Authorization: Bearer <token>` header from every request.
- Validates the JWT signature and expiry.
- Sets the `SecurityContext` with the authenticated user principal.
- WebSocket STOMP connections also validate the JWT during the initial HTTP handshake.
- JWT payload contains: `{ userId, email, authProvider: "EMAIL" | "GOOGLE" }`.

---

## 4. Session State Machine

The user progresses through 3 phases. The state machine enforces that no phase can be skipped:

```
ONBOARDING → CALIBRATION → EXECUTION
    │              │             │
    │              │             └─ Can access: Dashboard, Lab, Resources
    │              └─ Can access: Persona Reveal + Negotiation
    └─ Can access: Entry Gate + Micro-Interview
```

### Phase Transitions

| Transition | Trigger | What Happens |
| :--- | :--- | :--- |
| `ONBOARDING → CALIBRATION` | M6 returns `confidence_score > 90` during interview | `SessionService` updates phase. `PersonaService` stores the generated `LearnerPersona`. |
| `CALIBRATION → EXECUTION` | User clicks "Accept Quest" on Screen 03 | `TrackService` locks in the negotiated track. `SessionService` updates phase. Sets first node to `ACTIVE`. |

`PhaseGuard` is a utility called by controllers. If a request arrives for a resource that requires a later phase, it throws `PhaseViolationException` → the client receives a 403 with a redirect hint.

---

## 5. Track DAG Management

### 5a. Data Model

The track is stored in the `learning_tracks` table as a JSONB column:

```json
{
  "trackId": "react_custom_101",
  "userId": "u_abc123",
  "goal": "Build a real-time React dashboard with WebSockets",
  "nodes": [
    { "id": "n1", "title": "GraphQL Subscriptions", "type": "visual_theory", "status": "COMPLETED", "prereqs": [] },
    { "id": "n2", "title": "React Hooks & State", "type": "interactive", "status": "ACTIVE", "prereqs": ["n1"] },
    { "id": "n3", "title": "Performance Optimization", "type": "project", "status": "LOCKED", "prereqs": ["n2"] }
  ]
}
```

### 5b. Node Status Updates

`TrackService` manages transitions:

| Action | Method | Logic |
| :--- | :--- | :--- |
| Complete a node | `completeNode(userId, nodeId)` | Sets node to `COMPLETED`. Scans all nodes whose `prereqs` list only contains completed nodes → sets those to `ACTIVE`. |
| Insert remedial node | `insertRemedialNode(userId, newNode)` | Appends the new node to the `nodes` array. Updates the failed node's status to `ACTIVE` (user must re-attempt after remediation). Links the remedial node as a new prereq. **Capped at 2 remedial nodes per original node.** |
| Swap a node (negotiation) | `swapNode(userId, targetId, replacement)` | Replaces the target node's content (title, type) while preserving its position in the prereq chain. |

### 5c. Track Mutation on Quiz Failure

Quiz grading uses a **two-tier approach**:
- **Multiple-choice quizzes**: Graded locally in Java (`if (submitted == correctIndex) → pass`). No LLM call needed.
- **Free-text/code submissions**: Sent to M6's Closed-Loop Evaluator for LLM grading.

On failure, remedial nodes are inserted with a **cap of 2 per original node**:

```
QuizService.submitAnswer()
  → For MCQ: grade locally (submitted == correctAnswerIndex?)
  → For free-text: call M6 to grade
  → If pass: call TrackService.completeNode()
  → If fail:
      → Count existing remedial nodes for this parent node
      → If count < 2:
          → M6 generates remedial node with different modality
          → TrackMutationService.insertRemedialNode()
          → Uses optimistic locking (version column) to prevent race conditions
      → If count >= 2 (circuit breaker):
          → No new node. Instead, trigger a guided walkthrough:
          → Push AI Mentor message: "Let's work through this together step by step."
          → Unlock the next node anyway with a "needs_review" flag
  → Saves to PostgreSQL
  → Publishes track update to /topic/session/{id}/track-update via WebSocket
```

---

## 6. WebSocket Server (STOMP Broker)

### 6a. Configuration

```
WebSocketConfig:
  - Endpoint: /ws (SockJS fallback enabled for web)
  - Application destination prefix: /app
  - Broker destinations: /topic, /queue
  - User destination prefix: /user
  - Heartbeat: 10s send, 10s receive
```

### 6b. Channel Registry

| Channel | Direction | Purpose |
| :--- | :--- | :--- |
| `/app/session/{id}/chat-send` | Client → Server | Student sends a chat message |
| `/topic/session/{id}/chat-response` | Server → Client | AI reply pushed to client |
| `/topic/session/{id}/canvas-render` | Server → Client | Visualization payload for M2 Sandbox Canvas |
| `/topic/session/{id}/interventions` | Server → Client | Watchdog micro-quiz or nudge message |
| `/topic/session/{id}/track-update` | Server → Client | Track DAG has been mutated (node added/status changed) |
| `/app/session/{id}/canvas-interaction` | Client → Server | Student tapped a canvas node (forwarded to M6 for context) |
| `/app/session/{id}/heartbeat` | Client → Server | Activity heartbeat (mouse move, keypress, scroll) |

### 6c. Message Routing in ChatWebSocketController

```
@MessageMapping("/session/{id}/chat-send")
public void handleChat(@DestinationVariable String id, ChatIncoming message, Principal principal):
  1. Validate JWT principal
  2. Log activity event (ActivityService)
  3. Update heartbeat tracker (HeartbeatTracker)
  4. Determine chat mode from message.context.chatMode
  5. Call ChatRoutingService.route(message):
      → interview mode: forwards to M6.dynamicProfiler()
      → negotiation mode: forwards to M6.negotiateTrack()
      → mentor mode: forwards to M6.mentorExplain()
  6. Receive ChatResponse from M6
  7. If chatResponse.canvasPayload != null:
      → Send to /topic/session/{id}/canvas-render
  8. If chatResponse.trackUpdate != null:
      → Apply via TrackMutationService
      → Send to /topic/session/{id}/track-update
  9. Send chatResponse.reply to /topic/session/{id}/chat-response
  10. Persist message + response in chat_history table
```

---

## 7. Watchdog Background Daemon

### 7a. HeartbeatTracker (Persistent)

Heartbeat data is stored in a **PostgreSQL table** (not in-memory) to survive server restarts and support horizontal scaling:

```sql
CREATE TABLE session_heartbeats (
    user_id         UUID PRIMARY KEY REFERENCES users(id),
    last_activity   TIMESTAMP NOT NULL DEFAULT NOW(),
    intervention_level INT NOT NULL DEFAULT 0,  -- 0=none, 1=nudged, 2=quizzed
    session_paused  BOOLEAN NOT NULL DEFAULT FALSE  -- student can pause monitoring
);
```

Updated via `ON CONFLICT UPDATE` on every:
- Chat message received
- Activity heartbeat received
- Quiz submission
- Content load request

### 7b. WatchdogScheduler

A `@Scheduled(fixedRate = 30_000)` method (runs every 30 seconds):

```
SELECT * FROM session_heartbeats
  WHERE session_paused = FALSE
  AND user_id IN (SELECT id FROM users WHERE current_phase = 'EXECUTION')

For each row:
  elapsed = Duration.between(last_activity, now)

  ESCALATION PATTERN (not immediate quiz):

  If elapsed > 5 MINUTES and intervention_level == 0:
    → Send gentle nudge: "Still thinking? No rush — take your time."
    → Set intervention_level = 1

  If elapsed > 10 MINUTES and intervention_level == 1:
    → Call InterventionDispatcher.sendMicroQuiz(userId)
    → Set intervention_level = 2

  If elapsed > 72 HOURS:
    → Call M6.generateSmartNudge(userId, currentNodeContext)
    → Send nudge via push notification

  On any new activity heartbeat:
    → Reset intervention_level = 0
```

**Pause Session**: Students can tap a "Pause Session" button on the dashboard, which sets `session_paused = TRUE`. The Watchdog skips paused sessions entirely.

### 7c. InterventionDispatcher

Generates the micro-quiz payload:

```
1. Reads the user's current active node from TrackService
2. Calls M6.generateInterventionQuiz(nodeId, userPersona)
3. M6 asks the LLM to generate a quick, low-barrier question related to the active topic
4. Receives InterventionPayload:
   {
     "quizQuestion": "What HTTP status code represents a successful WebSocket upgrade?",
     "options": ["200 OK", "101 Switching Protocols", "301 Moved"],
     "correctAnswerIndex": 1,
     "source": "watchdog"
   }
5. Publishes to /topic/session/{userId}/interventions
6. Flutter client (M4) receives and renders the intervention banner in the chat
```

### 7d. Spaced Repetition Daemon (Feature 3)

A `@Scheduled(cron = "0 0 9 * * ?")` daemon (runs daily at 9:00 AM):
- Queries `completed_nodes` where completed_at was 3, 7, or 14 days ago.
- **Backlog Cap & Auto-Consolidation (L22 Fix)**: Caps active daily spaced repetition reviews to a **maximum of 2 per day**. If a student has > 5 overdue reviews, consolidates them into a single 3-question **"Refresher Challenge"** rather than firing dozens of individual micro-quizzes.
- Calls M6 to generate quick recall review question(s).
- Pushes the review quiz to `/topic/session/{userId}/interventions` with `"source": "spaced_repetition"`.

### 7e. Peer Analytics Service (Feature 2)

Calculates anonymous relative ranking across users on the same track:
- `GET /api/analytics/peer-percentile`
- Reads total completed nodes & average quiz scores across all users with matching `track_id`.
- **Sample Size Threshold (L23 Fix)**: Only calculates and displays percentile score when total track users $N \ge 15$. When $N < 15$, returns `{ "hasSufficientData": false, "completedNodes": 6, "totalTrackUsers": N }`.
- When $N \ge 15$, computes percentile score: `(users_behind / total_track_users) * 100`.
- Returns: `{ "hasSufficientData": true, "percentile": 73, "completedNodes": 6, "totalTrackUsers": 142 }`.

### 7f. Dynamic Auto-Rescheduling Service (Feature 4)

- `POST /api/schedule/reschedule`
- **Guilt-Free Auto-Shift (L24 Fix)**: When a scheduled calendar date passes without node completion, the daemon automatically shifts uncompleted nodes forward to remaining study days and redistributes workload evenly without triggering penalizing red "OVERDUE" alerts. Allows student to adjust daily minute commitments (e.g. 45 min $\rightarrow$ 20 min/day).

### 7g. Multi-Device Session Handling (L14 Fix)

- **Session Scoping**: Each active device generates a unique `session_id`. WebSocket channels are scoped to `session_id` (`/topic/session/{sessionId}/...`).
- **Active Session Sync**: When a user connects a new device, M5 sends a sync payload to other active sessions: `{ "event": "device_connected", "activeSessionId": "..." }`. The inactive device pauses Watchdog monitoring while preserving local UI state.

### 7h. Observability & System Monitoring (L16 Fix)

Uses **Micrometer** (Spring Boot Actuator) to expose real-time metrics on `/actuator/metrics`:
- `llm.pipeline.latency` — histogram of response times per pipeline (profiler, evaluator, explainer).
- `rag.cache.hit_rate` — ratio of pgvector hits vs. live discovery misses.
- `websocket.active_sessions` — gauge of currently connected STOMP sessions.
- `watchdog.interventions_sent` — counter of nudges, quizzes, and spaced repetition checks.

### 7i. Admin REST API (L19 Fix)

Exposes protected administrative endpoints for content curators & system monitors:
- `POST /admin/content/ingest` — manually trigger content ingestion & embedding for a CS topic.
- `GET /admin/students` — list active students, progress, and persona stats.
- `GET /admin/metrics` — real-time system health summary.

---

## 8. REST API Summary

| Method | Path | Auth | Purpose |
| :--- | :--- | :--- | :--- |
| POST | `/auth/register` | No | Register with email + password |
| POST | `/auth/login` | No | Login with email + password, return JWT |
| POST | `/auth/google` | No | Verify Google ID token, return JWT |
| GET | `/api/session/state` | JWT | Get current phase + progress |
| GET | `/api/persona/{userId}` | JWT | Get learner persona |
| POST | `/api/track/generate` | JWT | Trigger DAG generation from persona |
| POST | `/api/track/negotiate` | JWT | Swap/add/remove nodes |
| GET | `/api/track/{userId}` | JWT | Get full track with node statuses |
| POST | `/api/notes` | JWT | Save/update per-node student markdown note (UX15) |
| GET | `/api/notes/{nodeId}` | JWT | Fetch student markdown note for a node (UX15) |
| POST | `/api/diagrams/save` | JWT | Save canvas diagram payload to notes (UX14) |
| GET | `/api/certificate/{userId}` | JWT | Generate & fetch track completion certificate (UX18) |
| POST | `/admin/content/ingest` | Admin JWT | Trigger manual content ingestion for topic (L19) |
| GET | `/admin/metrics` | Admin JWT | System health & LLM latency dashboard data (L16/L19) |
| GET | `/api/content/{nodeId}` | JWT | Fetch learning content for a node |
| POST | `/api/quiz/generate` | JWT | Generate feedback gate quiz |
| POST | `/api/quiz/submit` | JWT | Submit quiz answer, get result |
| POST | `/api/quiz/intervention-submit` | JWT | Submit Watchdog / Spaced Repetition micro-quiz answer |
| GET | `/api/chat/history/{sessionId}` | JWT | Load chat history |
| POST | `/api/activity/heartbeat` | JWT | Report user activity event |
| POST | `/api/schedule/generate` | JWT | Generate AI study schedule (Feature 4) |
| GET | `/api/schedule/{userId}` | JWT | Get current daily study plan |
| GET | `/api/analytics/peer-percentile` | JWT | Get anonymous peer comparison percentile (Feature 2) |

---

## 9. Integration Points

| Touches Module | How |
| :--- | :--- |
| **M1–M4 (Flutter Client)** | M5 is the single backend gateway. All REST calls and WebSocket connections terminate here. |
| **M6 (AI Orchestration)** | M5 calls M6 as an internal service (method call, not HTTP). M6 handles all LLM interactions and returns structured responses. |
| **M7 (RAG Pipeline)** | M5 calls M7 to fetch content for a given node (topic + modality). M7 queries the vector DB and returns content URLs + transcripts. |
| **M8 (PostgreSQL)** | M5 reads/writes all tables via Spring Data JPA repositories. |
