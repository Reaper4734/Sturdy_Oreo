# Module 1: Flutter UI Shell — Implementation Specification

> **Tech Stack**: Flutter (Dart) · Spring Boot REST/WebSocket · GoRouter · Riverpod
> **Platforms**: Web, Android, Windows 11, macOS
> **Reference**: [frontend_visualization_spec.md](file:///c:/CP/Oreo/frontend_visualization_spec.md), [UI MODULE.docx](file:///c:/CP/Oreo/UI%20MODULE.docx)

---

## 1. Module Responsibility

This module owns the entire visual skeleton of the application — every screen, every transition, every adaptive layout. It is the container that the other 3 client modules (Sandbox Canvas, Video Player, Chat Interface) plug into.

---

## 2. Project Structure

```
lib/
├── main.dart                          # App entry, providers, theme
├── app/
│   ├── router.dart                    # GoRouter config (all routes + guards)
│   └── theme/
│       ├── app_theme.dart             # ThemeData with our dark-mode tokens
│       ├── colors.dart                # Color constants (--bg-darker, --accent-purple, etc.)
│       ├── typography.dart            # Outfit + JetBrains Mono text styles
│       └── glow.dart                  # Reusable BoxDecoration factories for neon glows
│
├── features/
│   ├── auth/                          # Screen 01: Entry Gate
│   │   ├── presentation/
│   │   │   ├── entry_gate_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── email_input_field.dart
│   │   │   │   ├── password_input_field.dart
│   │   │   │   └── google_sign_in_button.dart
│   │   │   └── controllers/
│   │   │       └── auth_controller.dart
│   │   └── data/
│   │       └── auth_repository.dart   # REST calls to /auth/register, /auth/login, /auth/google
│   │
│   ├── onboarding/                    # Screen 02: Micro-Interview
│   │   ├── presentation/
│   │   │   ├── micro_interview_screen.dart
│   │   │   └── widgets/
│   │   │       ├── chat_bubble.dart
│   │   │       ├── typing_indicator.dart
│   │   │       └── chat_input_bar.dart
│   │   └── data/
│   │       └── interview_repository.dart  # WebSocket to /topic/session/{id}/interview
│   │
│   ├── calibration/                   # Screen 03: Persona Reveal & Negotiation
│   │   ├── presentation/
│   │   │   ├── persona_reveal_screen.dart # Split-screen container
│   │   │   └── widgets/
│   │   │       ├── negotiation_chat_panel.dart   # Left 30%
│   │   │       ├── persona_radar_chart.dart      # Right 70% — radar/spider chart
│   │   │       ├── proposed_track_list.dart       # Right 70% — node list
│   │   │       └── accept_quest_button.dart
│   │   └── data/
│   │       └── negotiation_repository.dart  # REST: /track/negotiate, WS for live updates
│   │
│   ├── dashboard/                     # Screen 04: Command Center
│   │   ├── presentation/
│   │   │   ├── command_center_screen.dart
│   │   │   └── widgets/
│   │   │       ├── watchdog_timer_bar.dart        # Top: countdown display
│   │   │       ├── track_index_tree.dart          # Vertical skill tree
│   │   │       ├── track_node_card.dart           # Individual node (locked/active/complete)
│   │   │       └── micro_quiz_overlay.dart        # Slide-in quiz from Watchdog
│   │   └── data/
│   │       └── dashboard_repository.dart
│   │
│   ├── lab/                           # Screen 05: Learning Lab
│   │   ├── presentation/
│   │   │   ├── learning_lab_screen.dart  # Dual-pane container
│   │   │   └── widgets/
│   │   │       ├── adaptive_canvas_panel.dart     # Left 50% (hosts M2 + M3)
│   │   │       └── mentor_chat_panel.dart         # Right 50% (hosts M4)
│   │   └── data/
│   │       └── lab_repository.dart
│   │
│   └── resources/                     # Screen 06: Resource Map
│       ├── presentation/
│       │   ├── resource_map_screen.dart
│       │   └── widgets/
│       │       ├── resource_node_section.dart
│       │       └── resource_card.dart             # Pulsing cyan glow on active nodes
│       └── data/
│           └── resource_repository.dart
│
├── shared/
│   ├── widgets/
│   │   ├── glass_card.dart            # Reusable glassmorphic container
│   │   ├── neon_button.dart           # Glowing accent button
│   │   ├── animated_page_wrapper.dart # Shared fade/slide transition wrapper
│   │   └── responsive_scaffold.dart   # Adapts layout for mobile vs. desktop vs. web
│   ├── models/
│   │   ├── learner_persona.dart       # Dart class mirroring the LearnerPersona JSON
│   │   ├── learning_track.dart        # Dart class for LearningTrack + TrackNode
│   │   └── resource_item.dart
│   └── services/
│       ├── websocket_service.dart     # Singleton STOMP client manager
│       ├── api_client.dart            # HTTP client wrapper (Dio) with JWT interceptor
│       └── session_manager.dart       # Holds JWT, userId, current phase state
│
└── gen/                               # Auto-generated (freezed, json_serializable)
```

---

## 3. Navigation & Route Guards

We use **GoRouter** because it supports:
- Declarative routing with `redirect` guards (enforce state machine transitions).
- Deep linking (important for web builds).
- Shell routes for persistent layouts (e.g., the dashboard scaffold stays mounted while inner content swaps).

### Route Table

| Route Path | Screen | Guard Condition |
| :--- | :--- | :--- |
| `/` | Entry Gate (Screen 01) | None — always accessible |
| `/interview` | Micro-Interview (Screen 02) | Requires valid JWT (user authenticated) |
| `/reveal` | Persona Reveal (Screen 03) | Requires `persona_generated == true` from backend |
| `/dashboard` | Command Center (Screen 04) | Requires `track_accepted == true` |
| `/lab/:nodeId` | Learning Lab (Screen 05) | Requires node status == `active` or `completed` |
| `/resources` | Resource Map (Screen 06) | Requires `track_accepted == true` |

### Route Guard Implementation Strategy

```
GoRouter redirect logic:
1. Read SessionManager (a Riverpod provider holding auth state + phase).
2. If user has no JWT → redirect to `/`
3. If user has JWT but no persona → redirect to `/interview`
4. If user has persona but track not accepted → redirect to `/reveal`
5. Otherwise → allow navigation to requested route.
```

The **SessionManager** provider is hydrated on app launch by calling `GET /api/session/state` on the Java backend, which returns the user's current phase:
```json
{
  "userId": "u_abc123",
  "phase": "EXECUTION",
  "trackAccepted": true,
  "personaGenerated": true,
  "activeNodeId": "n2"
}
```

---

## 4. Design System Implementation

### 4a. Color Constants (maps to CSS tokens from frontend spec)

```
AppColors:
  bgDarker         = Color(0xFF0D0D12)     // App background
  bgCard           = Color(0x661E1E2A)     // Glassmorphic panel (40% opacity)
  fgPrimary        = Color(0xFFF3F4F6)     // High-contrast text
  fgSecondary      = Color(0xFF9CA3AF)     // Muted captions
  accentPurple     = Color(0xFF7B2CBF)     // Core theme
  accentCyan       = Color(0xFF00B4D8)     // System hooks / status
  accentGreen      = Color(0xFF38B000)     // Success / Quest completed
  accentWarning    = Color(0xFFFFB703)     // Watchdog alerts
```

### 4b. Glow Decorations

Reusable `BoxDecoration` factories:
```
GlowStyle.purple → BoxShadow(color: accentPurple.withOpacity(0.6), blurRadius: 15)
GlowStyle.cyan   → BoxShadow(color: accentCyan.withOpacity(0.6), blurRadius: 15)
GlowStyle.green  → BoxShadow(color: accentGreen.withOpacity(0.6), blurRadius: 15)
```

### 4c. Glass Card Widget

Every panel uses the same base:
```
Container:
  decoration:
    color: bgCard
    borderRadius: 16
    border: 1px solid white at 8% opacity
    backgroundBlendMode: overlay
  clipBehavior: Clip.antiAlias
  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12))
```

### 4d. Typography

```
Fonts to load (via google_fonts package or bundled assets):
  - Outfit (sans-serif) → headings, body text, buttons
  - JetBrains Mono (monospace) → code snippets, technical labels

TextTheme:
  displayLarge:  Outfit, 32px, bold, fgPrimary
  titleMedium:   Outfit, 20px, semibold, fgPrimary
  bodyMedium:    Outfit, 16px, regular, fgPrimary
  bodySmall:     Outfit, 14px, regular, fgSecondary
  labelSmall:    JetBrains Mono, 12px, regular, accentCyan
```

---

## 5. Screen-by-Screen Transition Animations

### 5a. Screen 01 → Screen 02 (Entry Gate → Micro-Interview)
* **Trigger**: Successful login (email/password verified or Google ID token accepted, JWT received).
* **Animation**: Full-screen **fade-out** of the Entry Gate (300ms ease-out), then **fade-in** of the Micro-Interview chat (400ms ease-in).
* **Implementation**: GoRouter `CustomTransitionPage` with a `FadeTransition`.

### 5b. Screen 02 → Screen 03 (Micro-Interview → Persona Reveal)
* **Trigger**: Backend returns `confidence_score > 90%`, frontend shows "View Eval & Adjust" button, user taps it.
* **Animation**: This is the big "Wow" moment. The chat container **slides left** from full-width to 30% width (500ms spring curve). Simultaneously, the Persona Canvas **slides in from the right** (500ms, staggered by 100ms).
* **Implementation**: Use an `AnimatedContainer` for the chat panel width. The Persona panel uses a `SlideTransition` with `Offset(1.0, 0.0) → Offset(0.0, 0.0)`.

### 5c. Screen 03 → Screen 04 (Persona Reveal → Command Center)
* **Trigger**: User taps "Accept Quest".
* **Animation**: Both panels **scale down** slightly (0.95x) and **fade out** (300ms), followed by a **slide-up** entrance of the Command Center dashboard (400ms).
* **Implementation**: GoRouter `CustomTransitionPage` combining `ScaleTransition` + `FadeTransition` for exit, `SlideTransition` for entrance.

### 5d. Screen 04 → Screen 05 (Command Center → Learning Lab)
* **Trigger**: User taps an active node in the track tree.
* **Animation**: The tapped node card **expands** outward to fill the screen (Hero animation), then resolves into the dual-pane Learning Lab layout.
* **Implementation**: Flutter's built-in `Hero` widget with a shared tag on the node card.

### 5e. Watchdog Micro-Quiz Slide-In (on Screen 04)
* **Trigger**: WebSocket receives an intervention payload from the backend Watchdog.
* **Animation**: Quiz panel **slides in from the right edge** of the screen (`translateX(100%) → translateX(0)`), with a pulsing `accentWarning` border glow.
* **Implementation**: An `AnimatedPositioned` or `SlideTransition` widget, triggered by a Riverpod state change when the WebSocket message arrives.

---

## 6. Adaptive Rendering (Backend-Driven UI Hints)

The Java backend attaches a `render_mode` field to the session state and to individual track nodes:

```json
{
  "render_mode": "visual",
  "hints": {
    "prefer_diagrams": true,
    "prefer_video_over_text": true,
    "code_font_size": "large"
  }
}
```

The Flutter UI Shell reads these hints and makes layout decisions:

| Hint | Effect on UI |
| :--- | :--- |
| `render_mode: "visual"` | Learning Lab (Screen 05) defaults to showing the Sandbox Canvas with diagrams. Video content is prioritized over articles. |
| `render_mode: "textual"` | Learning Lab shows structured text/markdown. Code blocks are expanded by default. |
| `prefer_diagrams: true` | Resource Map (Screen 06) sorts diagram/video resources above article/doc resources. |
| `code_font_size: "large"` | Increases JetBrains Mono size from 12px to 16px across all code display widgets. |

This is implemented via a `RenderModeProvider` (Riverpod) that the backend populates on session load. Individual widgets read from this provider to branch their layout.

---

## 7. Responsive Layout Strategy

Since this app targets Web, Android, Windows 11, and macOS, the layout must adapt:

| Breakpoint | Platform | Layout Behavior |
| :--- | :--- | :--- |
| **< 600px** | Android (phone) | Single-column layout. Split-screens (Screen 03, 05) become stacked vertically or use a tab switcher. Chat panel is a slide-up bottom sheet. |
| **600–1024px** | Android (tablet), small desktop window | Reduced split ratios (50/50 instead of 30/70). Sidebar panels become collapsible drawers. |
| **> 1024px** | Web, Windows 11, macOS | Full split-screen layouts as per the wireframe spec. All panels visible simultaneously. |

Implementation: A `ResponsiveScaffold` widget wraps every screen. It uses `LayoutBuilder` to read the available width and passes a `LayoutMode` enum (`compact`, `medium`, `expanded`) down to child widgets, which branch their build methods accordingly.

---

## 7b. Screen 06: Resource Map Detailed Specification (UX19 Fix)

Screen 06 (`/resources`) acts as the student's personal **searchable content library**:
- **Search & Filter Bar**: Filter resources by keyword, topic tag, or content type (Videos, Articles, Saved Diagrams, Code Snippets, Notes).
- **Saved Diagrams Gallery**: View all interactive diagrams saved from the Sandbox Canvas (M2). Tapping re-opens the interactive diagram overlay.
- **Personal Notes Section**: Markdown notes taken during modules, organized by node topic.
- **Watch History & Resume**: List of all studied videos with saved progress bars and 1-tap resume buttons.

## 7c. Theme System & Shortcuts (UX11 & UX12 Fixes)

- **Dark / Light Mode Toggle (UX11 Fix)**: App header includes a sun/moon toggle button. Theme state is persisted via `themeProvider` in `SharedPreferences`. Both themes retain neon accent highlights with adjusted high-contrast backgrounds (`bgDeepDark: #0a0e1a`, `bgDeepLight: #f4f6fc`).
- **Keyboard Shortcuts (UX12 Fix)**: Uses Flutter `Shortcuts` & `Actions` for power users:
  - `Enter`: Send chat message
  - `Space`: Toggle video play/pause
  - `Ctrl + K` / `Cmd + K`: Open global search palette
  - `Ctrl + /`: Toggle Mentor Chat sidebar
  - `Esc`: Dismiss modal / exit focus mode

## 7d. Guided Tour & Achievement Certificates (UX20 & UX18 Fixes)

- **Guided Onboarding Tour (UX20 Fix)**: Uses `tutorial_coach_mark` package. First-time users see a 4-step spotlight tour explaining the Mentor Chat, Sandbox Canvas, and Track Tree. Replay button available in settings.
- **Track Completion Certificate & Sharing (UX18 Fix)**: Upon completing 100% of a learning track, a modal displays a high-res shareable achievement card with stats (completion time, quiz score average, streak). Includes "Share to LinkedIn" and "Download PDF/PNG" buttons.

---

## 8. State Management Architecture (Riverpod)

### Key Providers

| Provider | Type | What It Holds |
| :--- | :--- | :--- |
| `sessionProvider` | `StateNotifier<SessionState>` | JWT token, userId, current phase (ONBOARDING/CALIBRATION/EXECUTION), activeNodeId |
| `personaProvider` | `StateNotifier<LearnerPersona?>` | The user's cognitive profile once generated |
| `trackProvider` | `StateNotifier<LearningTrack?>` | The full DAG of track nodes with live status |
| `renderModeProvider` | `Provider<RenderMode>` | Derived from persona — controls adaptive layout hints |
| `webSocketProvider` | `Provider<WebSocketService>` | Singleton STOMP connection, auto-reconnects |
| `interventionProvider` | `StreamProvider<InterventionPayload>` | Listens to WebSocket for Watchdog quiz pushes |

### Data Flow

```
App Launch
  → api_client calls GET /api/session/state
  → Response hydrates sessionProvider, personaProvider, trackProvider
  → GoRouter evaluates redirect guards based on sessionProvider.phase
  → User lands on the correct screen for their current state
```

---

## 9. Key Flutter Packages

| Package | Purpose |
| :--- | :--- |
| `go_router` | Declarative routing with redirect guards and deep linking |
| `flutter_riverpod` | State management (providers, notifiers, streams) |
| `dio` | HTTP client with interceptors (JWT injection, error handling) |
| `stomp_dart_client` | STOMP over WebSocket for real-time communication |
| `google_sign_in` | Native Google Sign-In flow (returns ID token for backend verification) |
| `speech_to_text` | Real-time voice-to-text input for hands-free chat (Feature 5) |
| `code_text_field` | Syntax-highlighted code editor for Code Playground (Feature 1) |
| `google_fonts` | Loading Outfit and JetBrains Mono typefaces |
| `flutter_animate` | Declarative micro-animations (fade, slide, scale chains) |
| `freezed` + `json_serializable` | Immutable data classes with JSON serialization |
| `fl_chart` | Radar/spider chart for persona visualization on Screen 03 |
| `responsive_framework` | Breakpoint management for cross-platform layouts |

---

## 10. Integration Points with Other Modules

| Touches Module | Integration Method | What M1 Provides / Consumes |
| :--- | :--- | :--- |
| **M2 (Sandbox Canvas)** | M1 provides the `adaptive_canvas_panel` container widget in Screen 05. M2 plugs its `CustomPainter` canvas into this container. | Container layout + render_mode hints |
| **M3 (Video Player)** | M1 provides the same `adaptive_canvas_panel` container. M3 plugs its video player + feedback gate modal into it. | Container layout + node context |
| **M4 (Chat Interface)** | M1 provides the `mentor_chat_panel` container in Screen 05 and the full-screen chat in Screen 02. M4 plugs its chat widget into these. | Container layout + session context |
| **M5 (Java Core Engine)** | M1 calls REST endpoints (auth, session state, track data) via `api_client`. Receives WebSocket events via `websocket_service`. | HTTP requests, WS subscriptions |
