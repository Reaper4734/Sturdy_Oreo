# Architecture Audit: Round 3 (New Features & Deep Edge Cases)

A targeted audit evaluating the 5 newly integrated features:
1. 🖥️ **Code Playground** (M2)
2. 📊 **Anonymous Peer Comparison** (M1/M5)
3. 🔄 **Spaced Repetition** (M5/M6/M8)
4. 📅 **AI Study Schedule** (M1/M5/M6/M8)
5. 🎤 **Voice Input** (M4)

---

## Part 1: Logical / Architectural Flaws (Round 3)

---

### Flaw L21: Code Playground Execution Isolation & Security (Feature 1)

**The Problem**: If code inside the Code Playground executes directly in the browser main thread or server environment without sandboxing, student code could access `localStorage`/cookies, trigger infinite loops that freeze the UI, or execute unwanted scripts.

**Fix**:
- **JavaScript/Web Playground**: Execute code inside an isolated **Web Worker** with zero DOM/storage access and a strict 2-second timeout termination.
- **Python/Java/C++ Playground**: Forward code execution to an isolated microservice (e.g., Judge0 or Docker container with read-only filesystem, 512MB RAM cap, and no external networking).

---

### Flaw L22: Spaced Repetition Backlog Accumulation (Feature 3)

**The Problem**: If a student is inactive for 2 weeks, memory review quizzes accumulate (3-day, 7-day, 14-day checks for 8 completed nodes = 24 pending review quizzes). Upon returning, the student is bombarded with a mountain of review notifications, causing panic and disengagement.

**Fix**:
- **Backlog Cap**: Cap active daily spaced repetition reviews to a maximum of **2 per day**.
- **Auto-Consolidation**: If > 5 reviews are overdue, collapse them into a single 3-question **"Refresher Challenge"** rather than firing 24 individual micro-quizzes.

---

### Flaw L23: Peer Percentile Cold Start Variance (Feature 2)

**The Problem**: For new or niche tracks (e.g., "Rust Kernel Drivers"), there may be only 2 or 3 total learners. Displaying *"You are ahead of 50% of learners"* when N=2 is statistically meaningless and misleading.

**Fix**:
- **Sample Threshold**: Only calculate and display the Peer Percentile widget when total track learners $N \ge 15$.
- **Fallback**: When $N < 15$, display absolute progress metrics instead (e.g., *"3 of 7 modules completed · On track for goal"*).

---

### Flaw L24: Rigid Study Schedule Causes "Overdue Guilt" (Feature 4)

**The Problem**: The AI Study Schedule assigns nodes to specific calendar dates. If a student misses Day 2 due to real-life commitments, past dates turn red ("OVERDUE"), making the student feel guilty and behind.

**Fix**:
- **Dynamic Auto-Rescheduling**: When a scheduled day passes without completion, the `StudyScheduleService` automatically shifts uncompleted nodes forward and redistributes remaining workload without displaying penalizing red alerts.
- **Adjust Pace CTA**: Provide a 1-tap "Adjust Pace" button allowing students to change their daily minute commitment (e.g., 45 min → 20 min/day).

---

### Flaw L25: Voice Input CS Term Phonetic Mismatches (Feature 5)

**The Problem**: Standard Speech-to-Text engines struggle with CS jargon. Spoken technical terms like `"useEffect"`, `"async/await"`, `"PostgreSQL"`, and `"gRPC"` get transcribed as `"you effect"`, `"a sink a weight"`, `"post gray SQL"`, and `"gee R P C"`.

**Fix**:
- **CS Jargon Phonetic Normalizer**: Apply a client-side regex/dictionary mapper in Flutter before sending text to chat:
  - `"you effect"` $\rightarrow$ `useEffect`
  - `"a sink a weight"` $\rightarrow$ `async/await`
  - `"post gray SQL"` $\rightarrow$ `PostgreSQL`
  - `"jee R P C"` $\rightarrow$ `gRPC`
- This ensures the prompt sent to M6 contains clean code terminology.

---

## Part 2: User Experience Flaws (Round 3)

---

### Flaw UX21: Code Playground Screen Real Estate Constraints (Feature 1)

**The Problem**: On Screen 05 (50/50 split), the 50% left pane contains the Code Playground (editor + console + instructions). On a 13" laptop, typing code in a 400px wide pane feels cramped.

**Fix**:
- Add a **"Focus / Expand Editor"** button on the Code Playground header.
- Tapping it smoothly expands the code panel to 85% width (collapsing the Mentor Chat into a narrow sidebar), giving ample space for multi-line coding.

---

### Flaw UX22: Quiz Visual Ambiguity Across 3 Contexts

**The Problem**: Quizzes now appear in 3 different scenarios:
1. Watchdog Inactivity Check
2. Feedback Gate (Module Completion)
3. Spaced Repetition Memory Review

If all 3 look identical, the student gets confused about why a quiz is appearing.

**Fix**: Distinct visual identity per quiz context:
- ⚡ **Watchdog Check**: Amber border (`accentWarning`), title: *"Quick Check (Inactivity)"*.
- 🎯 **Module Gate**: Purple glowing modal (`accentPurple`), title: *"Knowledge Checkpoint"*.
- 🧠 **Spaced Repetition**: Cyan glowing banner (`accentCyan`), title: *"Memory Refresh (3-Day Review)"*.

---

### Flaw UX23: Voice Input Accidental Auto-Submission (Feature 5)

**The Problem**: If voice recognition automatically sends the message after 2 seconds of silence, any background noise or false pause sends unedited, broken text to the AI Mentor.

**Fix**:
- **Never auto-submit voice input**.
- Transcribed text streams into the text field and stays highlighted.
- The Send button pulses, requiring an **explicit tap** to send. The student can review or edit text before sending.

---

### Flaw UX24: No Text-to-Speech (TTS) for Hands-Free Loop (Feature 5)

**The Problem**: Voice input lets students *ask* questions hands-free, but they still have to stop and *read* long AI replies on screen, breaking the hands-free workflow.

**Fix**:
- Add a **Speaker Icon (🔊)** next to AI message bubbles (`flutter_tts` package).
- Tapping it reads the AI reply aloud.
- When Voice Input is used, offer an auto-read toggle: *"Read AI replies aloud?"*.

---

### Flaw UX25: Peer Percentile Creates Unwanted Pressure

**The Problem**: While peer comparison motivates competitive students, anxious or slower learners may feel discouraged by seeing low percentile numbers (e.g., *"Ahead of 20% of learners"*).

**Fix**:
- Make the Peer Percentile widget **opt-in / togglable** in Settings.
- By default, frame low percentiles positively: instead of *"Ahead of 20%"*, display *"You're in the top tier of consistency this week!"* or hide percentile when below 40%, showing personal growth instead.
