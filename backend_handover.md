# Oreo Platform: Backend Handover Document

## 1. Project Status Summary
**Status**: `100% COMPLETE` (Phase 1 through Phase 4 Backend Objectives Achieved).
**Stack**: Java 21, Spring Boot 3.4.2, PostgreSQL 16 (with `pgvector` & `JSONB`), LangChain4j, WebSockets (STOMP).
**Validation**: Fully compiles and passes all integration tests (`./gradlew clean build`).

---

## 2. Core Architecture Delivered

### A. Database & Migrations (Flyway)
*   **Total Migrations**: 14 strictly versioned Flyway scripts (`V1` to `V14`).
*   **Key Schemas**:
    *   `users`: Core authentication table with password hashing.
    *   `learning_tracks`: Stores the modular learning path as natively parsed `JSONB`.
    *   `document_embeddings`: Uses the `pgvector` extension with a 768-dimension `hnsw` index for ultra-fast RAG vector math.
*   **Optimizations**: Disabled Spring's `open-in-view` anti-pattern. Hardcapped the HikariCP connection pool to `15` to preserve PostgreSQL scaling during WebSocket bursts.

### B. Security & Auth
*   **`SecurityConfig.java`**: Configured as strictly `STATELESS` (No `JSESSIONID` memory bloat).
*   **JWT Implementation**: Validates and signs tokens using `JwtAuthenticationFilter`.
*   **Error Boundaries**: Robust `GlobalExceptionHandler` intercepts database constraint violations (`DataIntegrityViolationException`) mapping them to clean 409 JSON payloads rather than messy 500 stack traces.

---

## 3. The AI Brain (LangChain4j & Gemini)
We wired Google's `gemini-3.1-flash-lite` and `text-embedding-004` into Spring Boot via LangChain4j.

**The 4 Active Pipelines (`com.oreo.engine.orchestration.pipelines`)**:
1.  **`DynamicProfilerPipeline` (M6)**: Ingests the student's micro-interview text, analyzes their cognitive archetype, and returns a structured JSON `LearnerPersona`.
2.  **`DagGeneratorPipeline` (M6)**: Uses the Persona to generate a custom-tailored Learning Track (a DAG of video and quiz nodes) and saves it to PostgreSQL as JSONB.
3.  **`QuizEvaluatorPipeline` (M6)**: Uses an `EmbeddingStoreContentRetriever` (RAG) to fetch relevant textbook context from PostgreSQL, comparing it against the student's answer to issue a `PASS`/`FAIL` grade.
4.  **`SmartNudgePipeline` (M5)**: Acts as a "learning coach" to dynamically generate 1-sentence motivational nudges for idle students.

---

## 4. Real-Time Transport (WebSockets)
The platform requires sub-second latency for UI animations and AI chatting.

*   **Standard Text STOMP (`/ws/orchestration`)**:
    *   `/app/interview/stream`: Streams the onboarding micro-interview chat token-by-token.
    *   `/app/canvas/stream`: Streams the text-based Sandbox Canvas Tutor explanations token-by-token.
    *   `/app/session/heartbeat`: Receives client pings to prove the student is active.
*   **Gemini Live Voice Proxy (`/ws/live`)**:
    *   A custom binary WebSocket handler (`GeminiLiveProxyWebSocketHandler`).
    *   Bypasses standard HTTP to proxy raw PCM audio directly from the student's microphone to the **Gemini 2.5 Flash Native Audio Dialog API** and streams the voice response back in real-time.

---

## 5. Background Daemons (Watchdog)
*   **`WatchdogSessionManager`**: A concurrent registry tracking exact millisecond activity for all connected WebSockets.
*   **`WatchdogDaemon`**: A Spring `@Scheduled` worker thread running every 30 seconds.
    *   *Logic*: Scans the registry. If a student is idle for > 3 minutes, it triggers the `SmartNudgePipeline`.
    *   *Delivery*: Pushes the nudge instantly down the STOMP connection to `/topic/session/{id}/interventions` forcing the UI to slide down a banner.

---

## 6. Next Steps for Frontend Developers (Flutter)
1.  **Auth**: Build Screen 01. Hit `/auth/register` or `/auth/login` and save the JWT.
2.  **WebSockets**: Import a STOMP client library (like `stomp_dart_client`). Connect to `ws://localhost:8080/ws/orchestration/websocket`.
3.  **Voice API**: Build the Canvas UI (Screen 05). Add a microphone button that opens a raw `WebSocketChannel` directly to `ws://localhost:8080/ws/live` to send and receive binary audio bytes.

The backend is complete. You may now safely pivot entirely to the Flutter UI implementation.
