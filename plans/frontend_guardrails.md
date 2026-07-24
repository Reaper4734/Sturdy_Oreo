# Oreo Frontend Guardrails & Locks

This document outlines the strict constraints, rate limits, and architectural guardrails that the Flutter UI must implement to interface correctly and safely with the Spring Boot backend. 

*Failure to implement these guardrails on the frontend will result in HTTP 429 (Too Many Requests) errors, WebSocket disconnections, and degraded AI performance.*

---

## 1. The Strict AI Rate Limit (The 15 RPM Rule)
The backend is currently powered by **Gemini 3.5 Flash Lite**, which carries a strict quota of **15 Requests Per Minute (RPM)**. 

### UI Locks Required:
*   **Action Debouncing:** You **must** implement a hard UI lock on any button that triggers an AI pipeline (e.g., "Explain", "Generate Map", "Chat"). If the user taps the button, it must instantly disable itself until the WebSocket stream completes or the HTTP request returns `200 OK`. 
*   **Double-Tap Prevention:** Ensure a fast double-tap does not send two identical WebSocket messages.
*   **Rate Limit Feedback:** If the backend returns a `429 Too Many Requests` (or if the WebSocket `onError` emits a rate limit message), the UI must catch this gracefully, display a "Thinking... please wait 10 seconds" toast, and lock input.

## 2. WebSocket Streaming (Canvas & Interview)
The backend handles real-time generation via STOMP WebSockets over `/topic/canvas/{sessionId}` and `/topic/interview/{sessionId}`.

### Connection Guardrails:
*   **One Active Stream:** A user session should never have more than one active generation stream at a time. Do not let the user ask a new Canvas question while the Interview agent is still typing.
*   **Handling the `done` Flag:** The backend stream will send `{"done": true}` when the AI finishes generating. The UI **must** listen for this specific flag to re-enable the chat input field.
*   **Heartbeat Management:** The UI must send periodic pings to `/session/heartbeat` to keep the `WatchdogDaemon` from purging the active session from memory.

## 3. The 1000-Word Semantic Buffer 
When the user asks a question on the Canvas, the backend dynamically fetches the last 1000 words of the video transcript leading up to the exact pause millisecond.

### UX Guardrails:
*   **Sync Accuracy:** The frontend **must** send the exact, precise video timestamp (in seconds) in the payload when the user hits "Send" on the chat. Do not send `0` or `null` unless the video hasn't started. 
*   **UI Pausing:** When the user focuses the chat input field, the video player **must automatically pause**. If the video keeps playing while they type, the timestamp sent to the backend will drift, and the AI will get the wrong context buffer.

## 4. Background Flashcard Generation
Currently, the backend automatically extracts flashcards (via an Async background thread) immediately after it finishes a Canvas explanation.

### UX Guardrails:
*   **Silent Generation:** Do not block the UI waiting for flashcards to generate. The backend handles this silently.
*   **No "Generate Flashcard" Button:** Since this burns an extra LLM request (costing us precious RPM quota), do not place a manual "Generate Flashcards" button in the chat UI. Let the backend handle the extraction passively to conserve tokens.

## 5. Strict Schema Typings
The backend has aggressively stripped out generic buckets (e.g., `Map<String, Object>`). Every pipeline returns a heavily structured, strongly-typed JSON payload.

### Flutter Data Classes:
*   **Do not use generic Maps (`Map<String, dynamic>`) in Flutter.** You must create explicit Dart data classes with `json_serializable` to map exactly to the backend responses.
*   **Example (Resource Map):** The `/api/resource-map/generate` endpoint returns a `ResourceMapSchema` containing a list of `BranchNode`s, which contain `AuthoritativeResource`s. The Flutter UI must exactly match this hierarchy. Missing fields will throw runtime errors on the frontend.

## 6. Markdown Rendering (Crucial UX)
The AI responds using GitHub Flavored Markdown. It will frequently use `**bolding**`, `*italics*`, `[links](url)`, and occasionally code blocks. 
*   **Widget Requirement:** You **cannot** use a standard Flutter `Text` widget for AI responses. You must use `flutter_markdown` or a similar robust renderer. 
*   **LaTeX / Math:** If the subject involves math, the AI may return LaTeX. Be prepared to implement a Markdown extension for math if formulas render raw.

## 7. Authentication Header & WebSocket Connect
The backend is secured by Spring Security.
*   **REST Calls:** Every HTTP request to `/api/**` must include the `Authorization: Bearer <JWT>` header.
*   **WebSocket Upgrade:** When establishing the STOMP connection (e.g., using `stomp_dart_client`), the JWT must be passed in the connect headers. If it is omitted, the socket connection will instantly drop with a 401 Unauthorized.

## 8. Stream Error Handling & Token Concatenation
When listening to `/topic/canvas/{sessionId}`, you are receiving raw stream events.
*   **Token Concatenation:** The backend sends individual sub-word fragments (e.g., `{"token": "The"}`). You must instantiate a stateful String buffer in your Flutter widget and append each incoming token to it, triggering a `setState()` to animate the text appearing. Do not replace the text on every tick.
*   **Session ID Routing:** You must generate a unique UUID for the `sessionId` on the client side, send it in the STOMP payload, and subscribe to exactly that UUID on the topic.
*   **Error Key:** If the LLM throws an exception (e.g., Rate Limited, API Key Invalid, Network Timeout), the backend will emit `{"error": "ErrorMessage"}` over the socket.
*   **UI Requirement:** The Flutter stream listener must explicitly check for the `error` key. If present, gracefully display a red error toast to the user and re-enable the chat input field. Do not leave the UI in an infinite "Loading..." state.

## 9. Hackathon Simulation (The Smart Nudge)
To satisfy the Hackathon rubric's "Intelligent Nudge" requirement (detecting 3 days of inactivity) without building a complex backend chron-job, the frontend will drive a simulation.
*   **The Hidden Button:** You must build a small, hidden "Dev Mode" button in the Flutter UI labeled `Simulate 3 Days Inactivity`.
*   **The Action:** When pressed, this button should fire a `POST` request to the backend's nudge endpoint (to be built) asking the AI to generate a contextual nudge.
*   **API Timeout Restrictions:** Flutter `http` (or Dio) default timeouts are ~10s. For AI-driven endpoints (specifically `POST /api/orchestration/planner/generate`), the HTTP timeout MUST be explicitly set to **at least 30 seconds**. The LLM and web-search tools take 10-15 seconds to return JSON, which will trigger false failures if default timeouts are used.
*   **Disabled Overlays:** During processing, a full-screen semi-transparent overlay blocking ALL taps must appear. 
*   **The Display:** When the backend returns the nudge string, display it as a native mobile Push Notification (using flutter_local_notifications) or as a prominent modal dialog on the screen to demonstrate the feature to the judges.

---

## 4. Assessment & Quiz Feedback UI (Active Learning)
To ensure the user understands their mistakes immediately (without waiting for the Remedial Task to be injected), the Flutter UI **must** render feedback instantly during the quiz loop.

*   **MCQ Instant Popups:** The `POST /api/orchestration/assessments/generate` payload provides an `explanation` string for every MCQ. If the user taps the wrong option, the UI must **instantly** display a modal or tooltip containing this `explanation` text.
*   **Subjective Grading Popups:** When the user submits a typed answer to `POST /api/orchestration/assessments/evaluate`, the UI must show a loading spinner. When the response arrives, immediately render a dialog showing their `score` and the LLM's `feedback` paragraph. 
*   **The Dual-Action Failure:** If `passed: false` is returned, the Flutter UI must simultaneously show the feedback dialog to the user AND silently trigger `POST /api/orchestration/planner/adapt` in the background to inject their YouTube homework.
