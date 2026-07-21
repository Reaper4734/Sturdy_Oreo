---
name: oreo-api
description: Knows the full Oreo platform API contract, database schema, WebSocket channels, and module boundaries. Use when generating endpoints, DTOs, services, or connecting frontend to backend.
---

# Oreo API Contract Skill

## Quick Reference

### Auth Endpoints (No JWT Required)
| Method | Path | Body | Returns |
| :--- | :--- | :--- | :--- |
| POST | `/auth/register` | `{ email, password, displayName }` | `{ token, userId }` |
| POST | `/auth/login` | `{ email, password }` | `{ token, userId }` |
| POST | `/auth/google` | `{ idToken }` | `{ token, userId, isNewUser }` |

### Core Endpoints (JWT Required)
| Method | Path | Returns |
| :--- | :--- | :--- |
| GET | `/api/session/state` | `{ userId, phase, trackAccepted, currentNodeId }` |
| GET | `/api/persona/{userId}` | `{ logic, visualization, applied, theoretical, renderMode }` |
| POST | `/api/track/generate` | `{ trackId, nodes[{id, title, type, prereqs, rationale, alternatives}] }` |
| POST | `/api/track/negotiate` | Updated track with swapped nodes |
| GET | `/api/track/{userId}` | Full track DAG with node statuses |
| GET | `/api/content/{nodeId}` | `{ contentType, sourceUrl, transcript, estimatedMinutes }` |
| POST | `/api/quiz/generate` | `{ question, options[], correctAnswerIndex }` |
| POST | `/api/quiz/submit` | `{ status, feedback, newNode? }` |
| POST | `/api/quiz/intervention-submit` | `{ correct, explanation }` |
| GET | `/api/chat/history/{sessionId}` | `[{ role, text, metadata, timestamp }]` |
| POST | `/api/activity/heartbeat` | `{ received: true }` |
| GET | `/api/watch-progress/{nodeId}` | `{ lastPosition, totalDuration, percentComplete }` |
| POST | `/api/schedule/generate` | `{ schedule[{dayNumber, date, assignedNodes, estMinutes}] }` |
| GET | `/api/schedule/{userId}` | Current study schedule |
| GET | `/api/analytics/peer-percentile` | `{ hasSufficientData, percentile?, completedNodes }` |
| POST | `/api/notes` | `{ saved: true }` |
| GET | `/api/notes/{nodeId}` | `{ markdownText, updatedAt }` |
| POST | `/api/diagrams/save` | `{ saved: true, diagramId }` |

### WebSocket STOMP Channels
| Channel | Direction | Payload |
| :--- | :--- | :--- |
| `/topic/session/{id}/chat` | Server → Client | AI chat reply + canvas payload |
| `/topic/session/{id}/canvas-render` | Server → Client | Canvas visualization payload |
| `/topic/session/{id}/interventions` | Server → Client | Watchdog quiz or spaced repetition quiz |
| `/topic/session/{id}/track-update` | Server → Client | DAG mutation notification |
| `/app/chat.send` | Client → Server | Student chat message |

### Database Tables (13 total)
`users`, `learner_personas`, `learning_tracks`, `chat_history`, `activity_log`,
`content_embeddings`, `session_heartbeats`, `watch_progress`, `study_schedules`,
`spaced_repetition_log`, `code_snippets`, `user_notes`, `saved_diagrams`

### Standard Error Response
```json
{
  "error": "ERROR_CODE",
  "message": "Human-readable message",
  "timestamp": "ISO-8601",
  "traceId": "uuid"
}
```

## Module Ownership
- **M5** (Java Core Engine): All REST endpoints, WebSocket config, Watchdog, Auth
- **M6** (AI Orchestration): LLM pipelines (Profiler, DAG, Evaluator, Nudge, Explainer, Recalibration, Schedule)
- **M7** (RAG Pipeline): Content retrieval, embedding, transcript fetching
- **M8** (Data Persistence): All Flyway migrations, JPA entities, repositories

## References
- Full specs: `c:\CP\Oreo\M5_java_core_engine.md` through `M8_data_persistence.md`
