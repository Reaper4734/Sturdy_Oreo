# Module 3: Video Player & Feedback Gate — Implementation Specification

> **Tech Stack**: Flutter `video_player` / `media_kit` · WebView (YouTube embeds) · Spring Boot REST
> **Platforms**: Web, Android, Windows 11, macOS
> **Reference**: [RAG MODULE.docx](file:///c:/CP/Oreo/RAG%20MODULE.docx) (Sections 2 & 4), [UI MODULE.docx](file:///c:/CP/Oreo/UI%20MODULE.docx) (Section 5)

---

## 1. Module Responsibility

This module handles **content consumption** and **knowledge verification**. It:
1. Plays video/article content fetched by the RAG Pipeline (M7) inside the Learning Lab canvas area.
2. Tracks playback progress and reports timestamps to the backend (enabling context-aware chat in M4).
3. Presents a **Feedback Gate** — a dynamically generated quiz modal that the student must pass to unlock the next track node.

---

## 2. Project Structure

```
lib/features/lab/player/
├── content_player.dart                # Root widget — switches between video and article
├── video/
│   ├── video_player_widget.dart       # Native video player for direct URLs
│   ├── youtube_embed_widget.dart      # WebView-based YouTube iframe embed
│   ├── video_controls_overlay.dart    # Custom play/pause, seek bar, fullscreen toggle
│   └── playback_tracker.dart          # Reports current timestamp to backend every 10s
│
├── article/
│   ├── article_reader_widget.dart     # Scrollable markdown/HTML article renderer
│   └── scroll_tracker.dart            # Reports scroll depth percentage to backend
│
├── feedback_gate/
│   ├── feedback_gate_modal.dart       # Full-screen overlay modal with quiz
│   ├── quiz_question_card.dart        # Single question with multiple-choice options
│   ├── quiz_result_view.dart          # Pass (confetti + unlock) or Fail (feedback + remedial)
│   └── confetti_overlay.dart          # Success celebration animation
│
├── models/
│   ├── content_item.dart              # { contentType, sourceUrl, transcript, estimatedMinutes }
│   ├── quiz_payload.dart              # { question, options[], correctAnswer }
│   └── quiz_result.dart               # { status: pass|fail, feedback, newNode? }
│
└── providers/
    ├── content_provider.dart          # Riverpod: holds current ContentItem for active node
    ├── playback_state_provider.dart   # Riverpod: current timestamp, isPlaying, isCompleted
    └── quiz_provider.dart             # Riverpod: quiz state (loading, answering, result)
```

---

## 3. Content Loading Flow

When the student opens a track node from the Command Center (Screen 04), M1 navigates to `/lab/:nodeId`. The content loading sequence:

```
Step 1: learning_lab_screen mounts → reads nodeId from route
         ↓
Step 2: content_provider calls GET /api/content/{nodeId}
        (Java backend internally calls M7 RAG Pipeline to fetch best content)
         ↓
Step 3: Backend returns ContentItem JSON:
        {
          "content_type": "video",
          "source_url": "https://www.youtube.com/embed/dGcsHMXbSOA",
          "transcript_snippet": "In React, state is how we remember...",
          "estimated_minutes": 12
        }
         ↓
Step 4: content_player.dart switches based on content_type:
        - "video" + YouTube URL → youtube_embed_widget
        - "video" + direct URL  → video_player_widget
        - "article"             → article_reader_widget
         ↓
Step 5: Player renders in the left pane of the Learning Lab (Screen 05)
```

---

## 4. Video Player Implementation

### 4a. YouTube Embeds (Most Common)

Since curated content is primarily YouTube links, we use a platform-aware approach:

| Platform | Strategy |
| :--- | :--- |
| **Android** | `webview_flutter` package — loads the YouTube embed iframe. Supports fullscreen. |
| **Web** | Standard HTML `<iframe>` via `HtmlElementView`. Native web behavior. |
| **Windows / macOS** | `webview_windows` or `webview_macos` — lightweight WebView rendering the embed URL. |

### 4b. Direct Video Files (Secondary)

For non-YouTube content (e.g., self-hosted MP4s):
- Use the `media_kit` package (better cross-platform support than the basic `video_player` package).
- Custom controls overlay (`video_controls_overlay.dart`) with:
  - Play/Pause button
  - Seek bar with chapter markers (if the backend provides chapter timestamps)
  - Playback speed selector (0.75x, 1x, 1.25x, 1.5x, 2x)
  - Fullscreen toggle

### 4c. Playback Tracking

`playback_tracker.dart` runs a periodic timer (every 10 seconds) that sends the current playback state to the Java backend:

```json
POST /api/activity/heartbeat
{
  "userId": "u_abc123",
  "nodeId": "n2",
  "event": "video_progress",
  "data": {
    "currentTime": 135,
    "totalDuration": 720,
    "percentComplete": 18.75
  }
}
```

This serves three purposes:
1. **Watchdog tracking** (M5): The backend uses these heartbeats to know the user is active. If heartbeats stop, the Watchdog triggers.
2. **Chat context** (M4/M6): When the student asks a question, the backend knows the exact video timestamp they are at, enabling the AI to reference that specific part of the transcript.
3. **Video resume** (UX6 Fix): The heartbeat also updates the `watch_progress` table (M8). If the student closes the app and returns, the client calls `GET /api/watch-progress/{nodeId}` and prompts: *"Resume from 8:15?"*. Tapping "Resume" seeks the video to the saved position.

---

## 5. Article Reader

For `content_type: "article"`, the article is rendered as a scrollable markdown/HTML document using `flutter_markdown` or `flutter_widget_from_html`.

**Scroll Tracking**: `scroll_tracker.dart` calculates the scroll depth as a percentage and reports it to the backend at the same 10-second interval. This allows the Watchdog to detect if a student has stopped scrolling midway.

**Highlighting**: The student can long-press to highlight a text passage. The highlighted text is captured and dispatched to M4 (Chat) via a local event, allowing the AI Mentor to respond: *"You highlighted 'useEffect cleanup.' Here is why that matters..."*

---

## 6. The Feedback Gate (Quiz Checkpoint)

### 6a. Trigger

When the student finishes watching the video (reaches > 90% playback) or scrolling the article (> 85% scroll depth), a "Complete Module" button appears. Tapping it triggers the Feedback Gate.

**Quiz Skip Option (UX4 Fix)**: For students with high cognitive profile scores (`logic ≥ 85 AND applied ≥ 80`), the Feedback Gate shows two buttons:
- **"Take Knowledge Check"** — standard quiz flow.
- **"Skip & Continue →"** — marks the node as completed without a quiz. A `skipped_quiz: true` flag is saved in the track node metadata. If the student struggles later, the system can retroactively recommend returning to skipped nodes.

Students with lower confidence scores only see the quiz — no skip option.

### 6b. Quiz Loading

```
Step 1: Student taps "Complete Module"
         ↓
Step 2: quiz_provider calls POST /api/quiz/generate
        {
          "nodeId": "n2",
          "userId": "u_abc123"
        }
         ↓
Step 3: Java backend (M5) forwards to AI Orchestration (M6)
        M6 uses the Closed-Loop Evaluator pipeline:
        - Takes the node's transcript (from M7)
        - Asks the LLM to generate a contextual quiz question
         ↓
Step 4: Backend returns QuizPayload:
        {
          "question": "If you update a state variable in React, what happens immediately?",
          "options": [
            "The page reloads",
            "The component re-renders",
            "The database updates"
          ],
          "correct_answer_index": 1
        }
         ↓
Step 5: feedback_gate_modal.dart opens as a full-screen overlay
```

### 6c. The Modal UI

```
+-------------------------------------------------------------+
|                                                             |
|              KNOWLEDGE CHECK: React State                    |
|                                                             |
|   "If you update a state variable in React,                  |
|    what happens immediately?"                                |
|                                                             |
|   +-------------------------------------------------------+ |
|   |  A) The page reloads                                  | |
|   +-------------------------------------------------------+ |
|   +-------------------------------------------------------+ |
|   |  B) The component re-renders              ← selected  | |
|   +-------------------------------------------------------+ |
|   +-------------------------------------------------------+ |
|   |  C) The database updates                              | |
|   +-------------------------------------------------------+ |
|                                                             |
|                      [ SUBMIT ANSWER ]                       |
|                                                             |
+-------------------------------------------------------------+
```

- Options are rendered as tappable `GlassCard` widgets.
- Selected option gets an `accentPurple` glowing border.
- "Submit Answer" button activates only after an option is selected.

### 6d. Grading & Result

```
Step 1: Student taps "Submit Answer"
         ↓
Step 2: quiz_provider calls POST /api/quiz/submit
        {
          "nodeId": "n2",
          "userId": "u_abc123",
          "selectedIndex": 1
        }
         ↓
Step 3: Java backend (M5) forwards to AI Orchestration (M6)
        M6 runs the Closed-Loop Evaluator pipeline:
        - If correct (≥ 80% threshold): returns { "status": "pass" }
        - If incorrect: returns fail + remedial node + feedback text
         ↓
Step 4: Backend returns QuizResult
```

### 6e. Pass Flow
```json
{ "status": "pass", "feedback": "Correct! State changes trigger re-renders." }
```
1. `quiz_result_view.dart` shows a **success card** with green glow.
2. `confetti_overlay.dart` fires a **confetti animation** (using `confetti` package) — gold and cyan particles.
3. After 2 seconds, auto-navigates back to the Command Center (Screen 04).
4. The `trackProvider` updates: current node → `completed`, next node → `active`.

### 6f. Fail Flow
```json
{
  "status": "fail",
  "feedback": "Not quite. State updates in React are asynchronous and trigger a re-render, not a page reload.",
  "action": "mutate_dag",
  "new_node": {
    "id": "n2_remedial",
    "title": "State Async Review",
    "type": "visual_theory",
    "prereqs": ["n2_attempt_1"]
  }
}
```
1. `quiz_result_view.dart` shows a **feedback card** with a warm amber glow (not aggressive red).
2. Displays the `feedback` text explaining why the answer was wrong.
3. After the student taps "Continue," navigates back to the Command Center.
4. The `trackProvider` updates: a **new remedial node** has been injected into the DAG by the backend. The dashboard shows it with a distinct visual indicator (amber/warning glow, "Review" label).

---

## 7. Integration Points

| Touches Module | How |
| :--- | :--- |
| **M1 (UI Shell)** | M1 provides the `adaptive_canvas_panel` container. M3's `ContentPlayer` and `FeedbackGateModal` render inside it. Navigation back to dashboard after quiz uses M1's GoRouter. |
| **M2 (Sandbox Canvas)** | When a student asks a question during video playback, M4 (Chat) triggers M6 (AI Orchestration), which may respond with a canvas payload for M2 to render alongside the paused video. The canvas and video can share the left pane via a vertical split or tab switcher. |
| **M4 (Chat Interface)** | M3 shares playback state (current timestamp, content transcript) with M4 so the AI Mentor has context. M3 publishes `playback_state` changes via `playback_state_provider` which M4 reads. |
| **M5 (Java Core Engine)** | M3 calls REST endpoints: `GET /api/content/{nodeId}`, `POST /api/quiz/generate`, `POST /api/quiz/submit`. M3 also sends activity heartbeats. |
| **M7 (RAG Pipeline)** | M3 does not call M7 directly. The Java backend (M5) mediates. M3 consumes the content URL and transcript that M7 originally fetched. |
