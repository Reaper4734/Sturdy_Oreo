# Architecture Audit: Logical & UX Flaws

A critical review of the system across all 8 modules. Every flaw listed has a proposed fix.

---

## Part 1: Logical / Architectural Flaws

---

### Flaw L1: Confidence Score Dead-End (M6 — Dynamic Profiler)

**The Problem**: The interview ends when `confidence_score > 90%`. But the LLM decides that score. What if it never reaches 90%? The student is stuck in an infinite interview with no exit.

**Scenario**: A vague or unusual student gives short answers. The LLM stays at 65% confidence forever. No "Generate My Track" button ever appears. Dead end.

**Fix**:
- Hard cap: After **8 turns maximum**, force the interview to end regardless of score.
- Soft cap: After 5 turns, show the button even if confidence is 70% — label it "Generate My Track (Draft)" so the student knows the profile might be less precise.
- Always show a "Skip Assessment" escape hatch that generates a generic starter track.

---

### Flaw L2: Quiz Grading is Wasteful (M6 — Closed-Loop Evaluator)

**The Problem**: For the Feedback Gate quiz, M6 generates the question AND the correct answer (`correct_answer_index: 1`). Then when the student answers, it sends the answer **back to the LLM** for grading. Why? You already know the correct answer — it's a deterministic comparison. You're burning an LLM API call (cost + latency) for a simple `if (selected == correct)` check.

**Fix**:
- Grade multiple-choice quizzes **locally in Java**: `if (submitted == correctIndex) → pass`.
- Only call the LLM for grading when the answer is **free-text/code** (subjective evaluation).
- Still call the LLM for the **remedial node generation** on failure — that's genuinely generative work.

---

### Flaw L3: Remedial Node Infinite Loop (M5 — Track Mutation)

**The Problem**: Every quiz failure inserts a new remedial node. If a struggling student fails repeatedly, the DAG grows endlessly: `n2 → n2_remedial_1 → n2_remedial_2 → n2_remedial_3 → ...`. There's no circuit breaker.

**Scenario**: Student fails the same concept 4 times. They now have 4 remedial nodes stacked up, making the track feel overwhelming and demoralizing — the opposite of the system's goal.

**Fix**:
- Cap remedial nodes at **2 per original node**. After 2 failures:
  - Switch strategy: instead of another remedial node, offer a **live guided walkthrough** (the AI Mentor walks them through the concept step by step in the chat).
  - Or: unlock the next node anyway with a "needs review" flag, letting them return later.

---

### Flaw L4: Watchdog In-Memory State (M5 — HeartbeatTracker)

**The Problem**: `HeartbeatTracker` is a `ConcurrentHashMap<String, Instant>` in memory. If the Java server restarts, crashes, or scales horizontally (multiple instances), all heartbeat data is lost. The Watchdog forgets who is active and who is idle.

**Fix**:
- Move heartbeat timestamps to **Redis** (lightweight key-value store with TTL support).
- Or: store in a PostgreSQL `session_heartbeats` table with `ON CONFLICT UPDATE`.
- For MVP: PostgreSQL is simpler. For production: Redis is faster and supports TTL natively.

---

### Flaw L5: Google + Email Account Collision (M5 — Auth)

**The Problem**: Student registers with `alex@gmail.com` via email/password. Later, they tap "Continue with Google" which resolves to the same `alex@gmail.com`. What happens?

**Possible bugs**:
- Duplicate user created → two accounts, split progress.
- 409 Conflict error → confusing for the student.
- Google login overwrites the password account → student can't use email login anymore.

**Fix**:
- On Google Sign-In: look up by email first.
  - If user exists with `auth_provider = EMAIL`: **link** the Google account. Set `auth_provider = BOTH`. Keep the password hash. Now both login methods work.
  - If user exists with `auth_provider = GOOGLE`: just log in.
  - If no user exists: create new with `auth_provider = GOOGLE`.
- Add `auth_provider` enum: `EMAIL`, `GOOGLE`, `BOTH`.

---

### Flaw L6: YouTube Transcript Unreliability (M7 — RAG Discovery)

**The Problem**: Not all YouTube videos have transcripts. Auto-generated transcripts for technical content are terrible — code syntax, variable names, and library names get mangled (`useState` becomes "you state", `async/await` becomes "a sink a weight").

**Impact**: If the AI Mentor is grounded in a garbled transcript, its answers will be wrong or nonsensical.

**Fix**:
- **Quality scoring**: After fetching a transcript, run a quick check — if it contains too many non-dictionary words or is too short relative to video length, flag it as low-quality.
- **Prefer manual transcripts**: YouTube API indicates whether a transcript is manual vs. auto-generated. Prioritize manual.
- **Fallback**: If no good transcript is available, use the video **title + description + comments** as lightweight context instead of a full transcript. The AI Mentor operates on Tier 1 (LLM native knowledge) with this minimal grounding.

---

### Flaw L7: DAG Mutation Race Condition (M5 — Track + Watchdog)

**The Problem**: The Watchdog can push a micro-quiz at the exact same time the student submits a Feedback Gate quiz on another node. Both try to mutate the DAG simultaneously — one might overwrite the other's changes since the `nodes` JSONB column is read-modify-written as a whole.

**Fix**:
- Use **optimistic locking**: add a `version` column to `learning_tracks`. Every update increments it. If two concurrent writes collide, the second one retries.
- Or: use PostgreSQL's `SELECT ... FOR UPDATE` row lock when mutating the track.

---

### Flaw L8: Persona Never Updates (M6 — Profiler)

**The Problem**: The `LearnerPersona` is generated once during onboarding and never recalibrated. But learning styles evolve — a "visual learner" might become more comfortable with text after 5 modules. A "low resilience" student might build confidence. The system keeps serving stale adaptive hints.

**Fix**:
- **Passive recalibration**: After every 3 completed nodes, M6 silently re-evaluates the persona based on:
  - Quiz pass/fail ratio (improving? → bump resilience score).
  - Content modality clicks (student keeps choosing articles over videos? → shift render_mode toward textual).
  - Chat interaction patterns (asking fewer questions? → higher applied score).
- Update the persona in the DB. The UI adapts gradually without interrupting the student.

---

### Flaw L9: No API Rate Limit Protection (M7 — Live Discovery)

**The Problem**: If 50 students sign up simultaneously during a demo, each picking a unique topic, the system fires 50 concurrent YouTube API + Google Search API calls. Free tier quotas (10,000 YouTube units/day, 100 Google searches/day) get exhausted instantly.

**Fix**:
- **Request deduplication**: If two students pick "Python Basics" within 5 minutes, the second one uses the first one's cached results. Don't fire duplicate API calls.
- **Rate limiter**: Use a `Semaphore` or `RateLimiter` (Guava/Resilience4j) to cap concurrent discovery requests (e.g., max 5 at a time).
- **Pre-seed demo topics**: Before the demo, pre-ingest the top 10 most likely CS topics. Live discovery only fires for truly unexpected picks.

---

### Flaw L10: No Error Recovery in WebSocket (M4/M5 — Chat)

**The Problem**: If the WebSocket connection drops mid-conversation (network blip, server restart), the chat panel shows... nothing. No reconnection, no message recovery. The student sees a frozen interface.

**Fix**:
- **Auto-reconnect**: `stomp_dart_client` supports reconnection with exponential backoff. Configure it.
- **Message recovery**: On reconnect, the client calls `GET /api/chat/history/{sessionId}` to reload missed messages.
- **Visual indicator**: Show a subtle "Reconnecting..." banner with a pulsing amber dot instead of a frozen screen.

---

## Part 2: User Experience Flaws

---

### Flaw UX1: Registration Contradicts "Zero Friction" Goal

**The Problem**: The KT directive says *"ZERO to chat in under 10 seconds."* But email/password registration requires: enter email, enter password (8 chars, 1 uppercase, 1 number), click register, wait for response. That's 20-30 seconds minimum. The original OTP flow was actually faster (enter phone → auto-submit).

**Fix**:
- Make **Google Sign-In the primary CTA** (biggest button, top position). One tap → done.
- Push email/password to a secondary "or register with email" link below.
- Remove aggressive password rules for the demo. Accept any 6+ character password. Tighten for production.

---

### Flaw UX2: 3-Minute Idle Timer is Punishing

**The Problem**: The Watchdog triggers a micro-quiz after 3 minutes of inactivity. But students regularly pause for legitimate reasons: reading paper notes, thinking about a concept, taking a bathroom break, checking their phone. A quiz popping up feels like a **punishment** for pausing, not an encouragement.

**Fix**:
- Increase idle threshold to **5 minutes** for in-session (Screen 05).
- Make the first intervention a **gentle nudge** ("Still thinking? No rush."), not a quiz.
- Only trigger a quiz on the **second** inactivity event. The escalation pattern: Nudge (5 min) → Quiz (10 min) → Nothing (respect their absence).
- Add a "Pause Session" button that explicitly disables the Watchdog. Student opts in/out of monitoring.

---

### Flaw UX3: No Way to Edit Persona After Calibration

**The Problem**: Once the student clicks "Accept Quest" on Screen 03, they're locked into their cognitive profile and track forever. If the system misjudged them (e.g., tagged them as "visual" but they actually prefer text), there's no way to correct it without starting over.

**Fix**:
- Add a **Settings / Profile** section accessible from the Command Center (Screen 04).
- Allow the student to manually adjust: `render_mode` (visual ↔ textual), resilience level, and preferred modality.
- Allow "Reset Track" — regenerate the DAG while keeping completed nodes. Changes apply going forward, not retroactively.

---

### Flaw UX4: Forced Quiz Feels Patronizing for Advanced Users

**The Problem**: Every module ends with a mandatory quiz gate. If a senior developer is reviewing React basics to fill a gap, being forced to answer *"What happens when you update state?"* before proceeding feels condescending. They might abandon the platform.

**Fix**:
- Make the quiz **optional for users with high confidence scores** (>85% persona logic + applied).
- Show: "Take the quiz to verify your understanding, or skip to the next module."
- Track skip rate. If a student skips quizzes but later struggles, the system can retroactively recommend review.

---

### Flaw UX5: Split-Screen Breaks on Mobile

**The Problem**: Screen 03 (30/70 split) and Screen 05 (50/50 split) are designed for ≥1024px screens. On a phone (360-414px), these become stacked vertical panels. The "cinematic" persona reveal loses its impact — instead of a dramatic split, the student sees a scrollable page. The negotiation flow (chat left, track right) becomes disjointed.

**Fix**:
- On mobile, use a **tab-based switcher** instead of a split:
  - Screen 03: Two tabs — "Chat" and "Your Profile". A floating "Accept Quest" FAB is always visible.
  - Screen 05: Two tabs — "Lesson" and "Mentor". A floating "💬" button switches between them.
- The "Wow" moment on mobile should be an **animated card flip** or a **modal reveal** instead of a horizontal split.

---

### Flaw UX6: No Video Progress Save

**The Problem**: Student watches 8 minutes of a 12-minute video, then closes the app. When they return, the video starts from 0:00. They have to scrub forward manually.

**Fix**:
- Persist `lastWatchedTimestamp` in the `activity_log` or a dedicated `watch_progress` table.
- On content load, check for saved progress: if found, show a "Resume from 8:15?" prompt.
- The playback tracker (M3) already sends heartbeats every 10 seconds — use the latest heartbeat as the resume point.

---

### Flaw UX7: Watchdog Timer Creates Anxiety

**The Problem**: The Command Center (Screen 04) shows `WATCHDOG TIMER: 03h : 42m : 11s` at the top. What does this countdown mean? If it's the idle detection timer, showing it publicly makes students feel **watched and pressured**. If it's a deadline, what happens at 00:00:00? The wireframe doesn't explain.

**Fix**:
- **Remove the visible countdown timer**. The Watchdog should operate silently in the background.
- Replace it with a positive metric: "🔥 Current Streak: 3 days" or "⏱ Time Invested: 2h 15m".
- The Watchdog still functions — it just doesn't display a ticking clock that creates stress.

---

### Flaw UX8: No Onboarding Skip for Returning Users

**The Problem**: If a returning user clears their app data or logs in on a new device, the state machine correctly restores their phase via `GET /api/session/state`. But what if a user wants to **restart** their journey with a different goal? Or what if they just want to browse the dashboard without re-doing the interview?

**Fix**:
- On login, if the user has an existing persona + track, show a **Welcome Back** screen:
  - "Continue your React track?" → Go to Dashboard.
  - "Start a new journey?" → Reset to Onboarding.
- Never force a returning user through the interview again unless they explicitly choose it.

---

### Flaw UX9: No Feedback After Watchdog Quiz

**The Problem**: The Watchdog micro-quiz slides in, the student answers, and... what? The current spec says "On correct: banner turns green, collapses after 2 seconds." But there's no explanation of *why* the answer was right or wrong. It feels like a random pop quiz with no educational value.

**Fix**:
- On correct: Show a one-line reinforcement: ✅ *"Right! 101 is the WebSocket upgrade code."* (2 seconds, then collapse).
- On wrong: Show the correct answer + a brief explanation: ❌ *"It's 101 Switching Protocols. 200 OK is for regular HTTP."* Keep visible for 5 seconds or until dismissed.
- Optionally: link to the relevant node — "Want to review this?" → navigates to the Learning Lab.

---

### Flaw UX10: No Celebration / Progress Visualization

**The Problem**: The system focuses heavily on interventions, quizzes, and corrections — but there's very little **positive reinforcement**. Completing a node gives you a green checkmark. That's it. No streak tracking, no milestones, no sense of accomplishment.

**Fix**:
- **Milestone celebrations**: After completing 3 nodes, 5 nodes, full track → show a full-screen achievement card with confetti.
- **Streak counter**: "You've studied 4 days in a row!" on the Command Center.
- **Progress ring**: A circular progress indicator showing "67% of your track complete" — more motivating than a vertical list of grey/blue/green nodes.
- **Weekly digest**: At the start of each week, show a summary: "Last week you completed 2 nodes and spent 3.5 hours learning. This week's target: Node 5."
