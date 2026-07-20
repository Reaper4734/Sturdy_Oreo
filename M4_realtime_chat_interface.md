# Module 4: Real-time Chat Interface — Implementation Specification

> **Tech Stack**: Flutter · STOMP over WebSocket · Riverpod StreamProvider · `flutter_animate`
> **Platforms**: Web, Android, Windows 11, macOS
> **Reference**: [AGENTIC MODULE.docx](file:///c:/CP/Oreo/AGENTIC%20MODULE.docx) (Section 1: Dynamic Profiler), [UI MODULE.docx](file:///c:/CP/Oreo/UI%20MODULE.docx) (Sections 2, 3, 5)

---

## 1. Module Responsibility

This module is the **conversational interface** — the user's primary channel for communicating with the AI Mentor. It appears in three contexts:
1. **Screen 02 (Micro-Interview)**: Full-screen chat during onboarding.
2. **Screen 03 (Persona Reveal)**: Left 30% panel for track negotiation.
3. **Screen 05 (Learning Lab)**: Right 50% panel as the AI Mentor sidebar.

In all contexts, the same underlying chat widget is used, but its behavior adapts based on the current **chat mode**.

---

## 2. Project Structure

```
lib/features/chat/
├── chat_panel.dart                    # Root widget — configurable for all 3 contexts
├── widgets/
│   ├── chat_message_list.dart         # Scrollable list of ChatBubble widgets
│   ├── chat_bubble.dart              # Individual message (AI or User styled)
│   ├── typing_indicator.dart          # Three bouncing dots animation
│   ├── chat_input_bar.dart            # Text field + send button (bottom-anchored)
│   ├── generate_track_button.dart     # Special CTA that appears when confidence > 90%
│   ├── intervention_banner.dart       # Watchdog micro-quiz injected into chat stream
│   └── context_chip.dart             # Shows current context: "Watching: React State @ 2:15"
│
├── models/
│   ├── chat_message.dart             # { id, role: "user"|"ai"|"system", text, timestamp, metadata? }
│   ├── chat_mode.dart                # Enum: interview | negotiation | mentor
│   └── intervention_payload.dart     # { quizQuestion, options[], source: "watchdog" }
│
├── services/
│   ├── chat_websocket_channel.dart   # STOMP subscription + publish for chat messages
│   └── context_assembler.dart        # Collects current context (video timestamp, selected canvas node)
│
└── providers/
    ├── chat_messages_provider.dart    # Riverpod: List<ChatMessage> for active session
    ├── chat_mode_provider.dart        # Riverpod: current ChatMode
    ├── typing_state_provider.dart     # Riverpod: bool — is AI currently "typing"?
    ├── confidence_provider.dart       # Riverpod: confidence_score from backend (interview mode)
    └── intervention_provider.dart     # Riverpod: StreamProvider listening for Watchdog pushes
```

---

## 3. Chat Modes

The `ChatPanel` widget accepts a `ChatMode` parameter that changes its behavior:

| Chat Mode | Used On | Behavior |
| :--- | :--- | :--- |
| `interview` | Screen 02 | Full-screen. AI drives the conversation using the 4-Phase Arc (Anchor → Friction → Scenario → Pivot). Input is disabled while AI is "typing." When `confidence_score > 90%`, the "Generate My Track" button fades in below the last AI message. |
| `negotiation` | Screen 03 (left panel) | Narrow panel. User can request track modifications ("swap REST for GraphQL"). AI confirms changes. Track updates appear live on the right panel (M1 handles the split). |
| `mentor` | Screen 05 (right panel) | Sidebar. Context-aware — reads the current video timestamp (from M3) and selected canvas node (from M2). Displays a `context_chip` at the top showing what the student is currently viewing. |

---

## 4. Message Flow (WebSocket Protocol)

### 4a. Sending a Message

```
Step 1: Student types message in chat_input_bar and taps Send
         ↓
Step 2: context_assembler.dart collects current context:
        {
          "videoTimestamp": 135,        // from M3 playback_state_provider (if in mentor mode)
          "selectedCanvasNode": "n2",   // from M2 canvas_interaction_provider (if any)
          "currentNodeId": "n2",        // from M1 route params
          "chatMode": "mentor"
        }
         ↓
Step 3: chat_websocket_channel publishes to /app/session/{id}/chat-send:
        {
          "text": "Why does useEffect need a cleanup function?",
          "context": { ... assembled context ... }
        }
         ↓
Step 4: chat_messages_provider appends the user message to the local list immediately
        (optimistic UI — message appears instantly with a "sending" indicator)
         ↓
Step 5: typing_state_provider sets to true → typing_indicator.dart starts animating
```

### 4b. Receiving a Response

```
Step 1: Java backend (M5) receives the message, routes it through M6 (AI Orchestration)
         ↓
Step 2: M6 selects the appropriate pipeline:
        - interview mode → Dynamic Profiler pipeline
        - negotiation mode → DAG negotiation pipeline
        - mentor mode → Sandbox Explainer pipeline
         ↓
Step 3: LLM returns structured JSON to M6. M6 parses and routes.
         ↓
Step 4: Java publishes the response to /topic/session/{id}/chat-response:
        {
          "reply": "The cleanup function prevents memory leaks by...",
          "internal_state": {              // Only present in interview mode
            "confidence_score": 85,
            "current_inferred_persona": { ... }
          },
          "canvas_payload": { ... },       // Optional: M2 visualization to render
          "track_update": { ... }          // Optional: M1 track modification (negotiation mode)
        }
         ↓
Step 5: chat_websocket_channel receives the message
         ↓
Step 6: typing_state_provider sets to false → typing indicator stops
         ↓
Step 7: chat_messages_provider appends the AI message:
        ChatMessage(role: "ai", text: reply, timestamp: now)
         ↓
Step 8: If canvas_payload exists → canvas_state_provider (M2) updates → Sandbox rerenders
Step 9: If track_update exists → trackProvider (M1) updates → Dashboard track list refreshes
Step 10: If confidence_score exists → confidence_provider updates
         → If > 90%, generate_track_button fades in
```

---

## 5. UI Component Details

### 5a. Chat Bubble

Two visual styles:

**User Bubble**:
- Aligned right.
- Background: `accentPurple` at 20% opacity with purple glow border.
- Text: `fgPrimary` (white).
- Rounded corners: top-left, top-right, bottom-left (no bottom-right for speech-tail effect).

**AI Bubble**:
- Aligned left.
- Background: `bgCard` (glassmorphic).
- Text: `fgPrimary`.
- Rounded corners: top-left, top-right, bottom-right (no bottom-left).
- Left accent strip: 3px wide `accentCyan` bar.
- **Text-to-Speech (TTS) Speaker Icon (UX24 Fix)**: A small `🔊` icon at the top-right of AI bubbles (powered by `flutter_tts`). Tapping it reads the AI reply aloud for hands-free learning.

**Entrance Animation** (using `flutter_animate`):
- Each new bubble slides up from 20px below its final position + fades in over 300ms.
- AI bubbles are staggered: if the response is multi-paragraph, each paragraph appears with a 150ms delay (simulates "streaming" feel even if the response arrives as a single block).

### 5b. Typing Indicator

Three dots that pulse in sequence:
- Dot 1 bounces up → 100ms later → Dot 2 bounces → 100ms later → Dot 3 bounces.
- Loop repeats every 800ms.
- Contained in a small `bgCard` glassmorphic bubble aligned left.

### 5c. Chat Input Bar

- Anchored to the bottom of the chat panel.
- Contains:
  - `TextField` with `fgSecondary` hint text ("Ask your mentor...").
  - **Voice Input Microphone Button** (`speech_to_text` package): A mic icon next to the input field. Tapping it activates real-time speech recognition with a glowing red waveform animation.
    - **CS Jargon Normalizer (L25 Fix)**: Passes raw speech output through a client-side phonetic regex dictionary (`"you effect"` $\rightarrow$ `useEffect`, `"a sink a weight"` $\rightarrow$ `async/await`, `"post gray SQL"` $\rightarrow$ `PostgreSQL`) before populating the input field.
    - **Manual Send Protection (UX23 Fix)**: Never auto-submits. Transcribed text populates and highlights in the `TextField`, requiring an explicit tap on the Send button so the user can review before dispatching.
  - Circular send button with `accentPurple` fill.
- **Input Locking**: When `typing_state_provider` is `true`, the text field and mic button are disabled and grayed out. This prevents the student from sending multiple messages while the AI is processing (as specified in UI MODULE.docx).
- **Context Chip** (mentor mode only): A small chip above the input bar shows: `📺 Watching: React State @ 2:15` — assembled from M3's playback state. Tapping the chip scrolls the video back to that timestamp.

### 5d. Generate Track Button (Interview Mode Only)

- Appears only when `confidence_provider.score > 90`.
- Entrance: fades in + slides up from below the last AI message bubble.
- Style: Full-width `NeonButton` with `accentCyan` glow and text: "Generate My Track →".
- On tap: calls `POST /api/track/generate` → navigates to Screen 03 (Persona Reveal).

### 5e. Intervention Banner (Watchdog & Spaced Repetition Push)

When M5's Watchdog or Spaced Repetition daemon pushes a micro-quiz via WebSocket:

1. `intervention_provider` (StreamProvider) receives the payload.
2. An `intervention_banner` widget slides into the chat message list as a special system message with **Context Visual Styling (UX22 Fix)**:
   - ⚡ **Watchdog Check**: `accentWarning` amber glowing border, header: `"Quick Check (Inactivity)"`.
   - 🧠 **Spaced Repetition Review**: `accentCyan` cyan glowing border, header: `"Memory Refresh (3-Day Review)"`.
   - 🎯 **Knowledge Checkpoint**: `accentPurple` purple glowing border, header: `"Module Knowledge Check"`.
   ```
   +---------------------------------------------------+
   |  ⚡ QUICK CHECK (Inactivity)                      |
   |                                                    |
   |  "What HTTP status code represents a successful    |
   |   WebSocket upgrade?"                              |
   |                                                    |
   |  [A] 200 OK    [B] 101 Switching    [C] 301 Moved |
   |                                                    |
   +---------------------------------------------------+
   ```
4. Answering the quiz sends the response to `POST /api/quiz/intervention-submit`.
5. On correct answer:
   - Banner border turns `accentGreen`.
   - Shows: ✅ *"Right! 101 Switching Protocols is the WebSocket upgrade code."*
   - Collapses after 3 seconds.
6. On wrong answer:
   - Banner border turns `accentWarning` (stays amber).
   - Shows: ❌ *"It's 101 Switching Protocols. 200 OK is for regular HTTP requests."*
   - Stays visible for 5 seconds or until dismissed.
   - Optionally shows: *"Want to review this?"* link that navigates to the related node in the track.

---

## 6. Chat History Persistence

- On each screen mount, `chat_messages_provider` calls `GET /api/chat/history/{sessionId}?mode={chatMode}` to load previous messages for the current context.
- This allows the student to leave and return without losing conversation context.
- Messages are stored on the backend in the `chat_history` table (M8) with the session ID, role, text, and metadata.

### WebSocket Reconnection (L10 Fix)

- `stomp_dart_client` is configured with **auto-reconnect** using exponential backoff (1s, 2s, 4s, max 30s).
- On disconnect, a subtle **amber banner** slides down at the top of the chat panel: *"⚠️ Reconnecting..."* with a pulsing dot.
- On successful reconnect:
  - Banner turns green: *"✅ Connected"* and fades out after 2 seconds.
  - Client calls `GET /api/chat/history/{sessionId}` to load any messages missed during the disconnect.
  - `heartbeat_provider` resumes sending activity signals.
- If reconnection fails after 60 seconds, banner changes to: *"Connection lost. [Retry]"* with a manual retry button.

---

## 7. Responsive Behavior

| Breakpoint | Layout |
| :--- | :--- |
| **< 600px (Phone)** | In mentor mode (Screen 05), the chat panel becomes a **slide-up bottom sheet** that covers 70% of the screen when opened. A floating "💬" button in the bottom-right toggles it. In interview mode (Screen 02), it remains full-screen. |
| **600–1024px (Tablet)** | Chat panel is a collapsible side drawer (can be toggled open/closed). |
| **> 1024px (Desktop/Web)** | Chat panel is always visible in its designated split-screen position. |

---

## 8. Integration Points

| Touches Module | How |
| :--- | :--- |
| **M1 (UI Shell)** | M1 provides the container panels (full-screen for Screen 02, left panel for Screen 03, right panel for Screen 05). M4 plugs its `ChatPanel` widget into these containers. M1 also triggers navigation to Screen 03 when the "Generate My Track" button is pressed. |
| **M2 (Sandbox Canvas)** | M4 reads `canvas_interaction_provider` (from M2) to know which canvas node the student selected. M4 also writes to `canvas_state_provider` when the AI response includes a `canvas_payload`, causing M2 to render a new visualization. |
| **M3 (Video Player)** | M4 reads `playback_state_provider` (from M3) to know the current video timestamp and content transcript. This context is attached to every chat message sent to the backend. |
| **M5 (Java Core Engine)** | M4 communicates via STOMP WebSocket channels: publishes to `/app/session/{id}/chat-send`, subscribes to `/topic/session/{id}/chat-response` and `/topic/session/{id}/interventions`. |
| **M6 (AI Orchestration)** | M4 does not call M6 directly. M5 routes chat messages to M6 for LLM processing. M4 only consumes the final response. |
