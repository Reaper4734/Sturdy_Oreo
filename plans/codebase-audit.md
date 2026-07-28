# Oreo AI — Codebase Audit Report

**Date:** 2026-07-28  
**Auditor:** Antigravity (Ponytail Mode)  
**Scope:** Full repository scan — Backend (Spring Boot), Frontend (Flutter), Database, Integration Layer  
**Purpose:** Hand this to the backend developer so they understand every problem, gap, and integration mismatch

---

## Executive Summary

The Oreo codebase has two distinct generations of code living side-by-side:

**Legacy Code:** Built rapidly without a phased plan. The backend has working AI pipelines, but the frontend is almost entirely powered by **mock data**. The two systems were never properly integrated.

The biggest risk is that the **Legacy Code is still live, still imported, and will confuse any new developer** who doesn't know which system is "real."

---

## Section 1: Frontend - Backend Integration Problems

### Problem 1: Two Parallel Data Universes

The frontend operates on **two completely separate data models** that have no relationship to each other:

| System | Frontend Model | Backend Source | Status |
|--------|---------------|----------------|--------|
| Workspace CRUD | `WorkspaceSummary` | `WorkspaceController` | Connected |
| Interview Chat | `HttpInterviewRepository` | `WorkspaceInterviewService` | Connected |
| Dashboard | `mock_dashboard_data.dart` | **None** | Mock Only |
| Roadmap Display | `mock_workspace_repository.dart` | **None** | Mock Only |
| Knowledge Graph | `mock_knowledge_graph_datasource.dart` | **None** | Mock Only |
| Mind Map | `mock_mind_map_repository.dart` | **None** | Mock Only |
| Flashcards | `mock_flashcard_repository.dart` | **None** | Mock Only |
| Learning Lab | `mock_learning_lab_repository.dart` | **None** | Mock Only |
| Persona | `mock_persona_repository.dart` | **None** | Mock Only |
| Mastery Tests | `mock_mastery_test_repository.dart` | **None** | Mock Only |
| Knowledge Hub | `mock_course_catalog.dart` | **None** | Mock Only |

**8 out of 10 frontend data sources are hardcoded mocks with zero backend connection.** The app "looks" functional but is a UI demo, not a product.

### Problem 2: WorkspaceModel is a God Object

`WorkspaceModel` (frontend) stores **everything** in a single class:

```
WorkspaceModel
    ├── persona (PersonaProfile)
    ├── subjectCluster (SubjectCluster / Mind Map)
    ├── roadmap (List<RoadmapNode>)
    ├── edges (List<RoadmapEdge>)
    ├── flashcards (List<FlashcardItem>)
    ├── canvasCells (List<CanvasGridCell>)
    ├── canvasObjects (List<CanvasObject>)
    ├── drawingPaths (List<DrawingPath>)
    ├── chatHistory (List<ChatMessage>)
    ├── activityFeed (List<ActivityEntry>)
    ├── tracks (List<DashboardTrack>)
    └── expandedRoadmapNodes, lastVideoTimestampSeconds...
```

This violates every data modeling principle. The backend correctly separates these into `Workspace`, `WorkspaceConversation`, `WorkspaceMessage`, and `WorkspaceLearningPlan`, but the **frontend still treats everything as one monolith**.

### Problem 3: Two Workspace Repository Stacks

The frontend has **two completely separate workspace systems:**

1. **Legacy:** `MockWorkspaceRepository` (1,211 lines, 57KB of hardcoded mock data) — used by the main app via `workspace_providers.dart`
2. **Phase 1+:** `HttpWorkspaceRepository` — calls the real backend but is **barely connected** to the main UI

The provider still points to Mock:
```dart
final workspaceRepositoryProvider = Provider<IWorkspaceRepository>((ref) {
  return MockWorkspaceRepository(); // <-- This is the problem
});
```

### Problem 4: Schema Mismatch

| Concept | Backend Schema | Frontend Model | Match? |
|---------|---------------|----------------|--------|
| Workspace ID | `UUID` | `String` | Partial |
| Roadmap Node | `LearningPlanSchema.Node` (id, title, description, difficulty, estimatedMinutes, tags, nodeType, learningObjective) | `RoadmapNode` (id, title, subtitle, type, estimatedHours, progressPercent, todaysGoal, children, flashcardsCount...) | **Completely Different** |
| Roadmap Edge | `LearningPlanSchema.Edge` (sourceId, targetId, relationshipType) | `RoadmapEdge` (from, to) | **Different field names, missing relationshipType** |
| Chat Message | `WorkspaceMessage` (id, sender, message, options_json, metadata_json) | `ChatMessage` (id, sender, text, options, attachments, metadata, progress, isComplete, extractedProfile) | **Partially Aligned** |
| Learning Plan | `WorkspaceLearningPlan` entity (versioned, validated, JSONB) | Does not exist | **Missing entirely** |

---


## Section 2: Frontend Dead Code (Ponytail Audit)

| Tag | What to Cut | Replacement | Path |
|-----|------------|-------------|------|
| `delete` | `mock_workspace_repository.dart` — 1,211 lines / 57KB of hardcoded seed workspaces. Largest file in the codebase. | Replace with real `HttpWorkspaceRepository`. | `shared/repositories/` |
| `delete` | `mock_interview_repository.dart` — Hardcoded 4-step conversation. Replaced by `HttpInterviewRepository`. | Remove entirely. | `shared/repositories/` |
| `delete` | `mock_flashcard_repository.dart` — No backend equivalent exists yet. | Remove. Re-create in Phase 9. | `shared/repositories/` |
| `delete` | `mock_learning_lab_repository.dart` — No backend equivalent. | Remove. Re-create in Phase 5. | `shared/repositories/` |
| `delete` | `mock_mind_map_repository.dart` — No backend equivalent. | Remove. Re-create in Phase 4. | `shared/repositories/` |
| `delete` | `mock_persona_repository.dart` — No backend equivalent. | Remove. `StructuredProfile` replaces this. | `shared/repositories/` |
| `delete` | `mock_mastery_test_repository.dart` — 10KB of hardcoded test data. | Remove. Re-create in Phase 9. | `shared/repositories/` |
| `delete` | `canvas_video_simulation.html` — 39KB standalone HTML at project root. | Remove. | project root |
| `delete` | `list_models.py` — Python script at project root. | Remove. | project root |
| `shrink` | `WorkspaceModel` — 129 lines carrying every artifact in one class. | Decompose into metadata-only model + separate fetches. | `shared/models/` |

### Net Removable (Frontend)
- **~7 mock repository files** (~1,500+ lines)
- **~2 standalone files** at project root
- Major simplification of `WorkspaceModel`

---

## Section 3: Missing Features (Required by Roadmap but Not Implemented)

| Feature | Phase | Backend | Frontend |
|---------|-------|---------|----------|
| Learning Roadmap UI (View, Edit, Confirm) | 3 | Done | **Not Started** |
| Mind Map Generation | 4 | Not Started | Legacy mock UI |
| Learning Lab Content | 5 | Not Started | Legacy mock UI |
| YouTube/Resource Integration | 6 | Legacy mock `SearchController` | Legacy mock |
| Dashboard (Real Data) | 7 | Not Started | Legacy mock UI |
| Knowledge Hub | 8 | Not Started | Legacy mock UI |
| Flashcards/Assessments | 9 | Legacy `AssessmentController` (disconnected) | Legacy mock UI |
| Authentication (Google OAuth) | 10 | Not Started (hardcoded UUID) | Not Started |

---

## Section 4: Architecture Anti-Patterns Found

### 1. Dual User ID Systems
- `WorkspaceController` falls back to `UUID("00000000-0000-0000-0000-000000000000")`.
- `WorkspaceLearningPlanController` hardcodes `UUID("11111111-1111-1111-1111-111111111111")`.
- **These are different UUIDs.** A workspace created via one controller is invisible to the other.

### 2. Mixed Package Organization
- Backend has both `service/` (singular) and `services/` (plural) packages. The `services/` package contains only legacy code.

### 3. No Error Handling Contract
- Backend returns raw Java exceptions as HTTP 500 errors.
- No standard `ErrorResponse` DTO.
- Frontend `catch` blocks display raw exception messages.

### 4. No API Versioning
- All endpoints are under `/api/` with no version prefix (e.g., `/api/v1/`).

### 5. Circular Import Risk
- `WorkspaceModel` imports from 7 different model files. Any change to any model risks breaking the God Object.

---

## Section 5: What Works Well (Keep As-Is)

| Component | Why It's Good |
|-----------|---------------|
| `WorkspaceStateMachine.java` | Clean state transition enforcement. |
| `WorkspaceInterviewService.java` | Proper conversation persistence, backend-owned profile approval. |
| `WorkspaceLearningPlanService.java` | Versioned plans, validated graphs, AI-driven edits, quality score. |
| `RoadmapValidator.java` | Never trusts LLM output. Validates DAG before persistence. |
| V11 + V12 Flyway migrations | Clean schema with proper FK constraints and indexes. |
| `HttpInterviewRepository` (Flutter) | Properly connected to backend interview endpoints. |


## Section 8: Summary for the Backend Developer

**What you need to know before writing any new code:**

1. **The frontend is 80% mock data.** When your API works in Postman, that does NOT mean the frontend is connected.
2. **There are two workspace systems.** The old `OrchestrationController` + `LearningTrack` system is dead. The new `WorkspaceController` + `WorkspaceInterviewService` + `WorkspaceLearningPlanService` system is live. Only work on the new system.
3. **The state machine is the backbone.** Every workspace status change MUST go through `WorkspaceStateMachine.validateTransitionOrThrow()`. Never bypass it.
4. **The two hardcoded user IDs are different.** `WorkspaceController` uses `00000000-...`, `WorkspaceLearningPlanController` uses `11111111-...`. This must be unified before Phase 3 Frontend.
5. **The backend owns all AI-generated data.** The frontend should never send generated content back. It only sends user intents (e.g., `{"instruction": "Add Docker"}`).
6. **Delete the legacy code FIRST.** Otherwise you will waste hours understanding code that has already been replaced.
