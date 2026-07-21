# Oreo Platform — Development Plan (2-Person Team)

---

## Team Split

| Person | Role | Owns |
| :--- | :--- | :--- |
| **You (Atharva)** | Backend + AI Lead | M5 (Java Core), M6 (AI Orchestration), M7 (RAG), M8 (Database) |
| **Partner** | Frontend Lead | M1 (Flutter Shell), M2 (Canvas), M3 (Video Player), M4 (Chat UI) |

> Both of you touch the **API contract** (Swagger docs) — that's the handshake point.

---

## 1. Development Cadence (No Formal Scrum)

Forget daily standups and sprint ceremonies. With 2 people, just do this:

| When | What | How |
| :--- | :--- | :--- |
| **Monday** | Quick sync (10 min) | WhatsApp/Discord: *"I'm working on X this week. Any blockers?"* |
| **Whenever you finish something** | Quick message | *"Auth endpoints are live on Swagger. Here's the base URL."* |
| **Sunday evening** | Weekly check | Run the app together for 15 min. See what works, what doesn't. |

### Weekly Goals (Not Sprints)

Set **1 goal per week per person**. Examples:
- *Week 1 — Atharva: "Auth + DB migrations working, testable via Swagger"*
- *Week 1 — Partner: "Flutter project scaffolded, routing + theme system done"*

Track goals in a **simple shared doc or GitHub Issues** — nothing more.

---

## 2. Git Workflow (Keep It Simple)

### Rules

| Situation | What to Do |
| :--- | :--- |
| Small fix (< 20 lines) | Commit directly to `main` |
| New feature or risky change | Create a branch → push → quick PR → merge |
| Breaking API change | **Always** a PR so both team members are aware |

### Branch Naming

```
feature/auth-google-login
feature/rag-youtube-fetcher
fix/watchdog-null-heartbeat
```

### Commit Messages (Keep Them Useful)

```
feat: add Google OAuth2 token verification
feat: implement 3-tier RAG retrieval pipeline
fix: handle null persona in DAG generator
test: add watchdog escalation unit tests
```

No need for strict conventional commits — just be descriptive enough that `git log --oneline` makes sense a month later.

---

## 3. Development Phases (Realistic for 2 People)

### Phase 1: Foundation (Week 1–2) — Both Work in Parallel

**You (Backend)**:
- [ ] Spring Boot project scaffold (Gradle, Java 21)
- [ ] PostgreSQL + Flyway: all 13 migration scripts
- [ ] Auth: register, login, Google token verify → JWT
- [ ] `GET /api/session/state` endpoint
- [ ] Swagger UI working at `localhost:8080/swagger-ui.html`

**Partner (Frontend)**:
- [ ] Flutter project scaffold (Riverpod, GoRouter, theme system)
- [ ] Screen 01 (Entry Gate) + Screen 02 (Interview Chat) UI shells
- [ ] Auth screens (Google Sign-In + Email/Password forms)
- [ ] Connect to backend auth endpoints

**Integration checkpoint**: Partner can register + login via the app, JWT is stored.

---

### Phase 2: AI Core (Week 3–4)

**You**:
- [ ] LangChain4j setup with Gemini Flash + failover
- [ ] Pipeline 1: Dynamic Profiler (interview chat)
- [ ] Pipeline 2: DAG Generator (persona → track)
- [ ] Track CRUD + negotiation endpoints
- [ ] WebSocket STOMP configuration

**Partner**:
- [ ] Screen 02: Full chat UI with typing indicator
- [ ] Screen 03: Persona Reveal + Track visualization
- [ ] WebSocket client connection (stomp_dart_client)

**Integration checkpoint**: Full flow — interview → persona → track generated → displayed.

---

### Phase 3: Content & Learning (Week 5–6)

**You**:
- [ ] M7: pgvector setup + embedding service
- [ ] M7: YouTube transcript fetcher + quality filter
- [ ] M7: 3-tier retrieval (cache → discovery → fallback)
- [ ] Pipeline 3: Quiz Evaluator (generate + grade)
- [ ] Content serving endpoints

**Partner**:
- [ ] Screen 05: Learning Lab (video player + chat split)
- [ ] M3: YouTube embed + playback tracking
- [ ] M3: Feedback Gate quiz modal
- [ ] Screen 04: Command Center dashboard

**Integration checkpoint**: Student watches video, takes quiz, gets pass/fail result.

---

### Phase 4: Watchdog & Real-Time (Week 7–8)

**You**:
- [ ] Heartbeat receiver + persistent heartbeats table
- [ ] Watchdog scheduler (nudge → quiz escalation)
- [ ] Pipeline 4: Smart Nudge generator
- [ ] Pipeline 5: Sandbox Explainer
- [ ] Pipeline 6: Gemini Live API integration (WebSockets for low-latency audio stream)
- [ ] Spaced Repetition daemon

**Partner**:
- [ ] M4: Intervention banner (quiz cards in chat)
- [ ] M4: Live Voice Convo toggle button (Gemini Live integration for Canvas context)
- [ ] M2: Sandbox Canvas (SVG, node graph, markdown renderers)
- [ ] WebSocket reconnect with visual indicator
- [ ] Screen 04: Positive metrics bar (streak, time, %)

**Integration checkpoint**: Idle student gets nudge → quiz. Canvas shows AI-generated diagrams.

---

### Phase 5: Polish & Demo (Week 9–10)

**Both together**:
- [ ] End-to-end flow testing (register → interview → learn → quiz → complete)
- [ ] Bug fixes
- [ ] Study Schedule feature
- [ ] Peer Analytics
- [ ] Code Playground (if time permits — this is a stretch goal)
- [ ] Demo preparation + presentation

---

## 4. Testing (Pragmatic, Not Academic)

With 2 people, you can't write tests for everything. **Test what can break you during the demo.**

### What to Test (Priority Order)

| Priority | What | How | Why |
| :--- | :--- | :--- | :--- |
| 🔴 **Must** | Auth flow (register, login, JWT) | Unit + Integration test | If auth breaks, nothing works |
| 🔴 **Must** | LLM pipeline responses (does JSON parse correctly?) | Unit test with mocked LLM responses | Malformed LLM output = crash |
| 🔴 **Must** | DAG generation (valid DAG, no cycles) | Unit test | Bad DAG = broken track |
| 🟡 **Should** | Watchdog escalation logic | Unit test | Wrong escalation timing = bad demo |
| 🟡 **Should** | pgvector similarity search | Integration test (Testcontainers) | RAG returning wrong content = confused student |
| 🟢 **Nice** | Quiz grading + remedial node insertion | Unit test | Secondary flow |
| 🟢 **Nice** | Spaced repetition scheduling | Unit test | Can verify manually |

### What NOT to Bother Testing

- Simple CRUD endpoints (Spring Data JPA handles this)
- UI widget rendering (Flutter handles this)
- Swagger documentation accuracy
- Config loading

### Quick Test Command

```bash
./gradlew test                    # Run all tests
./gradlew test --tests "*Auth*"   # Run only auth tests
./gradlew test --tests "*Watchdog*"  # Run only watchdog tests
```

---

## 5. Debugging During Development

### Your Best Friends

| Tool | What It Does | When to Use |
| :--- | :--- | :--- |
| **Swagger UI** | Visual API tester | Test every endpoint without Flutter |
| **IntelliJ Debugger** | Step through Java code | When something isn't working and logs aren't enough |
| **`application-dev.yml`** with `DEBUG` logging | See SQL queries, LLM prompts, full payloads | Always on during development |
| **Postman** | Save and replay API calls | Build a collection of test requests you reuse daily |
| **Docker Desktop logs** | See PostgreSQL errors | When DB queries fail silently |

### Logging That Actually Helps

```java
// Good: tells you WHAT happened and WITH WHAT data
log.info("[M6-Profiler] Generated persona for user={}, confidence={}, turns={}",
    userId, confidence, turnCount);

// Bad: tells you nothing useful
log.info("Done processing");
```

### LLM Debugging Tip

Save every LLM prompt + response to a file during development:

```java
log.debug("[LLM-PROMPT] pipeline={}\n{}", pipelineName, fullPrompt);
log.debug("[LLM-RESPONSE] pipeline={}\n{}", pipelineName, rawResponse);
```

This lets you see exactly what the AI received and returned when something goes wrong.

---

## 6. How You Two Communicate Changes

### The API Contract Is Sacred

The **Swagger docs** are the contract between you two. When you change an endpoint:

1. Update the endpoint.
2. Message your partner: *"Changed `/api/track/{userId}` response — added `rationale` field to each node. Check Swagger."*
3. Partner updates their Dart model class.

### Shared Postman Collection (Optional but Helpful)

Export your Swagger as a Postman collection. Share it via the repo:

```
docs/
├── postman_collection.json    ← Import this into Postman
├── sdlc_plan.md
└── architecture_audit.md
```

---

## 7. Project Structure in the Repo

```
Oreo/                              ← Git root (your repo)
├── docs/                          ← Architecture docs, audits, plans
│   ├── architecture_audit.md
│   ├── sdlc_plan.md
│   └── postman_collection.json
│
├── backend/                       ← Spring Boot project (YOU own this)
│   ├── src/main/java/com/oreo/
│   ├── src/main/resources/
│   │   ├── application.yml
│   │   ├── application-dev.yml
│   │   └── db/migration/          ← Flyway SQL files
│   ├── src/test/java/
│   ├── build.gradle
│   └── Dockerfile
│
├── frontend/                      ← Flutter project (PARTNER owns this)
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
│
├── M1_flutter_ui_shell.md         ← Module specs (reference docs)
├── M2_ai_sandbox_canvas.md
├── ...
├── M8_data_persistence.md
├── frontend_visualization_spec.md
├── .gitignore
└── README.md
```

---

## 8. One Rule Above All

> **"If it works in Swagger, ship it. Don't gold-plate."**

With 2 people and a demo deadline, perfectionism is the enemy. Get the flow working end-to-end first, then polish. A working demo with rough edges beats a perfect half-finished system every time.
