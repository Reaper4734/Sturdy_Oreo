# Module 6: AI Orchestration Layer — Implementation Specification

> **Tech Stack**: Java 21 · LangChain4j · Gemini / OpenAI API · Structured Outputs (JSON Mode)
> **Reference**: [AGENTIC MODULE.docx](file:///c:/CP/Oreo/AGENTIC%20MODULE.docx) (all 4 sections)

---

## 1. Module Responsibility

This module is the **brain router** — it does NOT contain the LLM. It is the Java service layer that:
1. Decides **which pipeline** to invoke based on the current context.
2. Constructs the **prompt** (assembles user profile, transcript, conversation history, and system instructions).
3. Calls the **LLM API** via LangChain4j.
4. Enforces the **output schema** (structured JSON, not free-form text).
5. Parses the response and **routes each field** to the correct downstream consumer (chat, canvas, track manager, watchdog).

Without this module, the system would have raw, uncoordinated LLM calls scattered everywhere. This is what makes the platform feel "agentic."

---

## 2. Project Structure

```
src/main/java/com/oreo/engine/orchestration/
├── OrchestrationService.java              # Public facade — M5 calls this, never the pipelines directly
│
├── pipelines/
│   ├── DynamicProfilerPipeline.java       # Onboarding 10-turn counselor
│   ├── DagGeneratorPipeline.java          # Persona → Learning Track DAG
│   ├── ClosedLoopEvaluatorPipeline.java   # Quiz grading + remedial node generation
│   ├── SmartNudgePipeline.java            # Inactivity re-engagement messages
│   └── SandboxExplainerPipeline.java      # Contextual explanations + visualization payloads
│
├── prompts/
│   ├── ProfilerSystemPrompt.java          # System instructions for the Dynamic Profiler
│   ├── DagGeneratorSystemPrompt.java      # System instructions for DAG generation
│   ├── EvaluatorSystemPrompt.java         # System instructions for quiz grading
│   ├── NudgeSystemPrompt.java             # System instructions for nudge generation
│   └── ExplainerSystemPrompt.java         # System instructions for sandbox explanations
│
├── schemas/
│   ├── ProfilerOutputSchema.java          # JSON schema: { reply_to_user, internal_state }
│   ├── DagOutputSchema.java               # JSON schema: { track_id, nodes[] }
│   ├── EvaluatorOutputSchema.java         # JSON schema: { status, feedback, action?, new_node? }
│   ├── NudgeOutputSchema.java             # JSON schema: { nudge_text }
│   ├── ExplainerOutputSchema.java         # JSON schema: { reply, canvas_payload? }
│   └── QuizGenerationSchema.java          # JSON schema: { question, options[], correct_answer_index }
│
├── context/
│   ├── ConversationMemory.java            # Manages per-session chat history window (last N turns)
│   ├── PersonaContextBuilder.java         # Assembles persona + traits into prompt-ready text
│   └── ContentContextBuilder.java         # Assembles transcript + node metadata into prompt-ready text
│
├── config/
│   └── LlmConfig.java                    # LangChain4j model configuration (API key, model name, temperature)
│
└── model/
    ├── OrchestrationRequest.java          # Input to OrchestrationService (text, context, mode)
    └── OrchestrationResponse.java         # Output from OrchestrationService (reply, canvasPayload?, trackUpdate?, internalState?)
```

---

## 3. The Orchestration Facade

`OrchestrationService.java` is the single entry point. M5 (Core Engine) calls it, never the individual pipelines.

```
public class OrchestrationService {

    public OrchestrationResponse process(OrchestrationRequest request) {
        return switch (request.getMode()) {
            case INTERVIEW    → dynamicProfilerPipeline.run(request);
            case NEGOTIATION  → handleNegotiation(request);
            case MENTOR       → sandboxExplainerPipeline.run(request);
            case QUIZ_GENERATE → closedLoopEvaluatorPipeline.generateQuiz(request);
            case QUIZ_GRADE   → closedLoopEvaluatorPipeline.gradeAnswer(request);
            case NUDGE        → smartNudgePipeline.run(request);
            case DAG_GENERATE → dagGeneratorPipeline.run(request);
        };
    }
}
```

---

## 4. Pipeline Deep Dives

### Pipeline 1: Dynamic Profiler (Onboarding Interview)

**Trigger**: Every chat turn during Screen 02 (Micro-Interview).

**Purpose**: Guide the student through a 4-Phase Arc while silently building a cognitive profile.

#### The 4-Phase Arc (Embedded in System Prompt)

| Phase | Goal | Example AI Question |
| :--- | :--- | :--- |
| **Anchor** | Identify their broad learning goal | "What are you trying to build or learn over the next 14 days?" |
| **Friction** | Identify learning blockers (EQ gauge) | "When you last tried learning this, where did you get stuck or lose interest?" |
| **Scenario** | Gauge problem-solving approach (IQ gauge) | "When you encounter a new API, do you prefer raw code or a structural diagram first?" |
| **Pivot** | Confirm understanding, ask permission to build plan | "I think I have a solid picture. Ready to see your profile?" |

> **UX16 Fix**: Friction questions are **observational, not emotional**. The system prompt includes: *"Never ask the student directly about their emotions. Infer emotional patterns from behavioral descriptions."* This prevents the interview from feeling invasive or like a therapy session.

#### Prompt Structure

```
[System Prompt]:
  You are an AI learning counselor. Guide the user through a 4-phase interview.
  Phase 1 (Anchor): Ask about their goal.
  Phase 2 (Friction): Ask about past learning blockers. Use observational language, not emotional.
    Do NOT ask "what frustrated you" — instead ask "where did you get stuck or lose interest?"
  Phase 3 (Scenario): Ask about their problem-solving style.
  Phase 4 (Pivot): Summarize and ask for permission.

  On EVERY response, you must return this exact JSON structure:
  {
    "reply_to_user": "<your natural language response>",
    "internal_state": {
      "domain_identified": <bool>,
      "eq_identified": <bool>,
      "modality_identified": <bool>,
      "confidence_score": <0-100>,
      "current_inferred_persona": {
        "domain": "<string>",
        "iq_logic": "<Visual|Textual|Applied|Theoretical>",
        "eq_resilience": "<string description>"
      }
    }
  }

[Conversation History]:
  - User: "I want to build a real-time dashboard with React and WebSockets."
  - AI: { reply_to_user: "Great goal! ...", internal_state: { confidence_score: 45, ... } }
  - User: "CSS positioning has always been frustrating for me."

[Current User Message]:
  "CSS positioning has always been frustrating for me."
```

#### Output Handling

```
LLM returns:
{
  "reply_to_user": "That makes total sense. CSS can be incredibly frustrating...",
  "internal_state": {
    "domain_identified": true,
    "eq_identified": true,
    "modality_identified": false,
    "confidence_score": 75,
    "current_inferred_persona": {
      "domain": "Frontend",
      "iq_logic": "Visual",
      "eq_resilience": "Easily frustrated, needs early wins"
    }
  }
}

OrchestrationService routes:
  → reply_to_user → ChatResponse.reply → M5 pushes to WebSocket → M4 renders
  → confidence_score → ChatResponse.internalState → M5 pushes to client
      → If ≥ 70 (after 5+ turns): M4 shows "Generate My Track" button
  → current_inferred_persona → **persisted in chat_history.metadata** (L18 Fix)
      On reconnect: loaded from last chat_history entry to resume interview seamlessly
```

#### Safety Net: Turn Cap (Prevents Infinite Interview)

The Dynamic Profiler tracks the number of completed turns. Hard rules override the confidence score:

| Turn Count | Behavior |
| :--- | :--- |
| Turns 1–4 | Normal interview. Button hidden. |
| Turn 5 | If `confidence_score ≥ 70%`: show "Generate My Track" button. |
| Turn 8 (hard cap) | Force-end the interview regardless of score. Show the button with label "Generate My Track (Draft)". If confidence is below 50%, generate a generic starter track and let the student negotiate it on Screen 03. |
| Any turn | A "Skip Assessment" link is always visible (small text below the chat). Generates a default track based on the stated goal alone. |

---

### Pipeline 2: DAG Generator

**Trigger**: User taps "Generate My Track" (confidence ≥ 70% after 5+ turns, or hard cap at turn 8).

**Purpose**: Translate the inferred persona into a structured Directed Acyclic Graph of learning nodes.

#### Prompt Structure

```
[System Prompt]:
  You are a curriculum designer. Given a learner's cognitive profile, generate a
  personalized learning track as a DAG.

  Rules:
  - Low Resilience (EQ) → break into 15-20 micro-nodes with early wins
  - High Resilience (EQ) → 5-8 large project-based nodes
  - Visual learner (IQ) → set node type to "visual_theory" or "interactive"
  - Textual learner (IQ) → set node type to "article" or "documentation"
  - Each node must have a unique ID, title, type, prereqs list, rationale, and alternatives
  - prereqs must form a valid DAG (no cycles)
  - rationale: a 1-sentence explanation of WHY this node matters for the student's goal
  - alternatives: 2-3 topic alternatives the student could swap this node for

  Return this exact JSON:
  {
    "track_id": "<generated_id>",
    "goal": "<user's stated goal>",
    "nodes": [
      {
        "id": "n1",
        "title": "...",
        "type": "...",
        "prereqs": [],
        "rationale": "Your dashboard needs real-time data. This teaches you how to subscribe to live updates.",
        "alternatives": ["gRPC Streaming", "Server-Sent Events", "Socket.io"]
      },
      ...
    ]
  }

[Learner Persona]:
  Domain: Frontend (React + WebSockets)
  IQ Logic: Visual
  EQ Resilience: Easily frustrated, needs early wins
```

#### Output Handling

```
LLM returns the DAG JSON.

OrchestrationService routes:
  → DAG JSON → M5's TrackService.createTrack(userId, dag)
  → TrackService writes to PostgreSQL
  → M5 transitions user phase: ONBOARDING → CALIBRATION
  → M5 pushes the full track to the client via WebSocket
  → M1 navigates to Screen 03 (Persona Reveal) showing the proposed track
```

---

### Pipeline 3: Closed-Loop Evaluator

**Trigger**: Student submits a quiz answer (Feedback Gate on Screen 05) or completes a module.

**Purpose**: Grade the answer against the specific material studied. On failure, generate a remedial node.

#### Sub-function A: Generate Quiz

```
[System Prompt]:
  You are a test designer. Given the following learning material transcript,
  generate ONE practical multiple-choice question to test the student's understanding.

  IMPORTANT: The student has already been asked these previous questions for this node.
  You MUST generate a DIFFERENT question that tests a different aspect of the material.

  Return:
  {
    "question": "<question text>",
    "options": ["<A>", "<B>", "<C>"],
    "correct_answer_index": <0|1|2>
  }

[Previous Questions for This Node] (L13 Fix):
  - "If you update a state variable in React, what happens immediately?"
  - (empty if first attempt)

[Material Transcript]:
  "In React, state is how we remember things between renders..."
```

> **After 3+ quiz attempts** on the same node, the system switches to a **free-text question** instead of MCQ — forces genuine understanding rather than elimination guessing.

#### Sub-function B: Grade Answer

```
[System Prompt]:
  You are a learning evaluator. The student just answered a quiz question.
  Grade their answer. If incorrect, explain why and generate a remedial learning node
  that changes the modality (e.g., if they read text, now try video).

  Return:
  {
    "status": "pass" | "fail",
    "feedback": "<explanation>",
    "action": "none" | "mutate_dag",
    "new_node": {                          // Only if status == "fail"
      "id": "<remedial_node_id>",
      "title": "<remedial topic>",
      "type": "<different modality>",
      "prereqs": []
    }
  }

[Quiz Context]:
  Question: "If you update a state variable in React, what happens immediately?"
  Correct Answer: "The component re-renders"
  Student's Answer: "The page reloads"
  Original Material Modality: "article"
```

---

### Pipeline 4: Smart Nudge Generator

**Trigger**: M5 Watchdog detects 72+ hours of inactivity.

**Purpose**: Generate a contextual, emotionally-aware re-engagement message.

#### Prompt Structure

```
[System Prompt]:
  You are a supportive learning coach. A student has been inactive.
  Write a short, warm re-engagement message that acknowledges the difficulty
  of the topic they are stuck on and offers a low-friction way to resume.

  Tailor your tone to their EQ profile:
  - Low Resilience: Extra supportive, normalize the struggle
  - High Resilience: Direct and challenging, appeal to their competitive side

  Return:
  { "nudge_text": "<your message>" }

[User Context]:
  Stuck on: "n2 - React Hooks & State" (inactive 3 days)
  EQ Profile: "Low Resilience — Easily frustrated, needs early wins"
```

#### Output Example

```json
{
  "nudge_text": "I noticed we paused right before React State. It's a notoriously tricky concept. Want to do a quick 2-minute visual recap together to get the momentum back?"
}
```

---

### Pipeline 5: Sandbox Explainer

**Trigger**: Student asks a question in Mentor Chat (Screen 05) while watching a video or interacting with the canvas.

**Purpose**: Generate a contextual explanation + (optionally) a structured visualization payload for the Sandbox Canvas (M2).

#### Prompt Structure

```
[System Prompt]:
  You are an AI tutor. The student is currently studying a specific topic.
  Answer their question using ONLY the concepts explained in the provided material.

  If the explanation would benefit from a visual diagram, also generate a canvas_payload.
  Supported payload types: "svg", "node_graph", "markdown", "annotated_image".

  Return:
  {
    "reply": "<your text explanation>",
    "canvas_payload": {                    // Optional — include only when visual helps
      "type": "node_graph",
      "caption": "...",
      "nodes": [...],
      "edges": [...]
    }
  }

[Current Material Transcript]:
  "The useEffect hook runs after every render. The cleanup function runs before
   the component unmounts or before the effect runs again..."

[Video Timestamp]: 135 seconds (2:15)

[Selected Canvas Node]: "useEffect Hook" (if the student tapped a node in M2)

[Student Question]:
  "Why does useEffect need a cleanup function?"
```

#### Output Handling

```
LLM returns:
{
  "reply": "The cleanup function prevents memory leaks by closing subscriptions...",
  "canvas_payload": {
    "type": "node_graph",
    "caption": "useEffect Lifecycle",
    "nodes": [
      { "id": "mount", "label": "Component Mounts", "x": 50, "y": 50, "style": "neon-cyan" },
      { "id": "effect", "label": "useEffect Runs", "x": 200, "y": 50, "style": "neon-purple" },
      { "id": "cleanup", "label": "Cleanup Runs", "x": 200, "y": 150, "style": "neon-green" },
      { "id": "unmount", "label": "Component Unmounts", "x": 350, "y": 150, "style": "neon-cyan" }
    ],
    "edges": [
      { "from": "mount", "to": "effect", "label": "after render", "animated": true },
      { "from": "effect", "to": "cleanup", "label": "before next effect", "animated": true },
      { "from": "cleanup", "to": "unmount", "label": "on unmount", "animated": false }
    ]
  }
}

OrchestrationService routes:
  → reply → ChatResponse.reply → M5 pushes to /topic/session/{id}/chat-response → M4 renders in chat
  → canvas_payload → ChatResponse.canvasPayload → M5 pushes to /topic/session/{id}/canvas-render → M2 renders the diagram
```

---

## 5. Conversation Memory Management

Each pipeline needs conversation history to maintain context. `ConversationMemory.java` manages this:

| Strategy | When Used |
| :--- | :--- |
| **Sliding Window** (last 10 turns) | Dynamic Profiler, Sandbox Explainer — keeps recent context without exceeding token limits |
| **Full History** | DAG Generator — needs the entire interview to extract the complete persona |
| **No History** | Smart Nudge, Quiz Generation — single-shot prompts with no prior turns needed |

Memory is stored in the `chat_history` table (M8) and loaded on demand.

---

## 6. Pipeline 6: Passive Persona Recalibration (L8 Fix)

**Trigger**: Automatically after every **3 completed nodes**. No student interaction required.

**Purpose**: The persona generated during onboarding becomes stale as the student progresses. This pipeline silently recalibrates the cognitive profile based on observed behavior — not another interview.

#### Input Data (Assembled by M5)

```json
{
  "current_persona": { "logic": 72, "visualization": 88, "applied": 65, "theoretical": 45 },
  "recent_behavior": {
    "quiz_pass_rate": 0.83,
    "avg_video_watch_percent": 92,
    "avg_article_scroll_percent": 45,
    "content_modality_clicks": { "video": 8, "article": 2, "diagram": 5 },
    "chat_questions_asked": 12,
    "remedial_nodes_triggered": 1,
    "avg_time_per_node_minutes": 25
  }
}
```

#### What It Adjusts

| Signal | Persona Update |
| :--- | :--- |
| Quiz pass rate rising (60% → 85%) | Bump `logic` and `applied` scores up |
| Student keeps picking articles over videos | Shift `render_mode` from `visual` → `textual` |
| Fewer chat questions over time | Increase `applied` score (more self-sufficient) |
| Zero remedial nodes triggered | Bump `eq_resilience` (confidence growing) |
| Long time-per-node (>40 min average) | Lower node complexity in future DAG adjustments |

#### Implementation

This does **not** require an LLM call. It's pure Java logic in `PersonaRecalibrationService`:

```
After every 3rd node completion:
  1. M5 assembles recent_behavior from activity_log
  2. PersonaRecalibrationService applies weighted adjustments:
     - visualization += (video_clicks / total_clicks) * 10
     - applied += quiz_pass_rate * 5
     - render_mode = video_clicks > article_clicks ? "visual" : "textual"
  3. Updated persona saved to learner_personas table
  4. render_hints recalculated
  5. Next content fetch uses updated modality preferences
```

The student never sees a "recalibration" event — the UI just gradually adapts.

---

## 7. Pipeline 7: AI Study Schedule Generator (Feature 4)

**Trigger**: Called when track is accepted on Screen 03 or when student requests a schedule re-adjustment.

**Purpose**: Takes the track DAG, node estimated durations, and student's target completion date/daily time commitment to generate a structured daily study plan.

#### Prompt Structure

```
[System Prompt]:
  You are an academic planner. Given a learning track DAG, estimated node completion times,
  and the student's target completion deadline, generate a daily study schedule.

  Rules:
  - Distribute nodes evenly across available study days.
  - Group smaller nodes together if daily budget permits.
  - Leave buffer days before major project/assessment nodes.
  - Account for prerequisite dependencies (do not schedule a node before its prereqs).

  Return this exact JSON:
  {
    "target_completion_date": "2026-08-05",
    "daily_study_minutes": 45,
    "schedule": [
      {
        "day_number": 1,
        "date": "2026-07-21",
        "assigned_nodes": ["n1"],
        "estimated_minutes": 40,
        "objective": "Master GraphQL Subscriptions basics"
      },
      {
        "day_number": 2,
        "date": "2026-07-22",
        "assigned_nodes": ["n2"],
        "estimated_minutes": 50,
        "objective": "Build React Hooks and State Sync"
      }
    ]
  }

[Input Data]:
  Target Deadline: 14 days
  Available Time: 45 mins/day
  Track Nodes: [{id: "n1", est_min: 40}, {id: "n2", est_min: 50}, {id: "n3", est_min: 60}]
```

#### Spaced Repetition Quiz Generator (Feature 3)

Under Pipeline 3 (Closed-Loop Evaluator), a sub-function handles **Spaced Repetition Review Quizzes** triggered at 3, 7, and 14 days post-node completion:

```
[System Prompt]:
  You are generating a Spaced Repetition Review Quiz for a node the student completed [X] days ago.
  Generate 1 fast recall question to reinforce memory retention.

  Return:
  {
    "question": "<memory check question>",
    "options": ["<A>", "<B>", "<C>"],
    "correct_answer_index": <0|1|2>,
    "retention_tip": "<1-line memory hook>"
  }
```

---

## 8. LangChain4j Configuration

```
LlmConfig:
  Failover Chain (L11 Fix):
    Primary:   Gemini 2.5 Flash  (cheapest, fastest, generous free tier)
    Fallback:  Gemini 2.5 Pro    (higher quota, different endpoint)
    Emergency: OpenAI GPT-4o-mini (completely independent provider)
    → LangChain4j FallbackChatModel wraps all three. On error/timeout, auto-switches.
    → Every failover event is logged for monitoring.

  Temperature:
    - Dynamic Profiler: 0.7  (conversational, warm)
    - DAG Generator: 0.3     (precise, structured)
    - Evaluator: 0.2         (deterministic grading)
    - Smart Nudge: 0.8       (creative, empathetic)
    - Sandbox Explainer: 0.5 (balanced)
  Max Tokens: 2048 per response
  Response Format: JSON (structured output mode enforced)
  Timeout: 30 seconds per provider (then failover triggers)
  Retry: 2 attempts per provider with exponential backoff

  Secrets Management (L20 Fix):
    - API keys stored in environment variables, NOT in code or application.properties.
    - Required env vars: GEMINI_API_KEY, OPENAI_API_KEY (fallback)
    - Spring Boot reads via: @Value("${GEMINI_API_KEY}")
    - For production: use GCP Secret Manager or AWS Secrets Manager.
```

---

## 7. Integration Points

| Touches Module | How |
| :--- | :--- |
| **M5 (Java Core Engine)** | M5 is the only caller. It invokes `OrchestrationService.process()` and routes the returned `OrchestrationResponse` fields to the appropriate downstream services (chat, canvas, track manager, WebSocket). |
| **M7 (RAG Pipeline)** | M6 calls M7 to retrieve transcripts and content metadata before constructing prompts. The transcript is injected into the system prompt to ground the LLM's responses. |
| **M8 (PostgreSQL)** | M6 reads conversation history from `chat_history` and persona data from `learner_personas` via M5's services. M6 does not write to the DB directly — it returns data to M5, which handles persistence. |
