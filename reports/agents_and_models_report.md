# Technical Audit Report: Agents & Model Pipelines

**Target Component**: AI Orchestration Engine & LangChain4j Agent Pipelines  
**Module Reference**: `com.oreo.engine.orchestration.pipelines`  
**Reviewer Role**: Senior Code Reviewer & AI System Architect  
**Audit Date**: July 24, 2026  

---

## Executive Summary

The AI Orchestration layer of the **Oreo Platform** contains 8 specialized agent pipelines built using LangChain4j (`0.36.2`) declarative `@AiService` interfaces and primary Google Gemini models (`gemini-3.5-flash-lite`). The agent system dynamically adapts curriculum DAG complexity, cognitive profiling, flashcard extraction, code execution grading, and visual canvas rendering.

---

## Agent Pipeline Inventory & Technical Analysis

### 1. Dynamic Profiler Pipeline (`DynamicProfilerPipeline.java`)
- **Purpose**: Evaluates student chat responses during onboarding.
- **Output**: Populates `ProfilerOutputSchema` with boolean flags (`domainIdentified`, `eqIdentified`, `modalityIdentified`), confidence score, and inferred persona.
- **Rules**: Asks clarifying questions until confidence reaches threshold.

### 2. DAG Generator Pipeline (`DagGeneratorPipeline.java`)
- **Purpose**: Generates personalized learning paths as Directed Acyclic Graphs.
- **Resilience Logic**:
  - Low Resilience (EQ) $\rightarrow$ Breaks curriculum into 15–20 micro-nodes with immediate early wins.
  - High Resilience (EQ) $\rightarrow$ Generates 5–8 large project-based nodes.
- **Modality Rules**:
  - Visual Learner $\rightarrow$ Assigns `visual_theory` or `interactive`.
  - Textual Learner $\rightarrow$ Assigns `article` or `documentation`.
- **Database Integration**: Saves resulting `LearningTrack` entity in `LearningTrackRepository`.

### 3. Syllabus Analyzer Pipeline (`SyllabusAnalyzerPipeline.java`)
- **Purpose**: Deconstructs raw course syllabi or video transcripts into structured skill nodes with explicit prerequisite dependencies.
- **Constraint**: System prompt mandates English translation for all titles and descriptions regardless of source transcript language.

### 4. Sandbox Explainer & Visual Canvas Pipeline (`SandboxExplainerPipeline.java`)
- **Purpose**: Generates interactive HTML5 Canvas visualization payloads (`canvas-render`) and step-by-step concept explanations when a student pauses or asks questions.

### 5. Flashcard Generator Pipeline (`FlashcardGeneratorPipeline.java`)
- **Purpose**: Extracts Anki-style Q&A flashcards (`frontQuestion`, `backAnswer`) from lesson content for spaced repetition ingestion.

### 6. Code Grader & Coding Challenge Pipelines (`CodeGraderPipeline.java` & `CodingChallengePipeline.java`)
- **Purpose**: Evaluates student code submissions against test cases, detecting syntax errors, edge-case failures, and computational complexity.

### 7. Resource Map Pipeline (`ResourceMapPipeline.java`)
- **Purpose**: Searches external developer documentation and recommended learning assets using Tavily Web Search Engine (`TavilyWebSearchEngine`).

### 8. Streaming Orchestration Service (`StreamingOrchestrationService.java`)
- **Purpose**: Manages real-time token streaming using `StreamingChatLanguageModel` (`GoogleAiGeminiStreamingChatModel`).

---

## Findings & Vulnerability Assessment

> [!NOTE]
> **Strengths**: The declarative `@AiServices` pattern provides concise prompt-to-POJO mapping and clean separation of concerns across pipeline components.

> [!WARNING]
> **API Key Fallback Risk**: `LlmConfig` injects `@Value("${oreo.llm.gemini-api-key:dummy-gemini-key}")`. If an invalid key is present in production environments, pipelines throw unhandled `LangChain4jException` during `@AiServices` invocation rather than returning structured error fallbacks.

---

## Test Cases & Verification Results

| Test ID | Test Description | Target Method | Status | Findings / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `TC-AGT-01` | DAG track entity persistence | `DagGeneratorPipeline.generate` | **PASS** | Correctly maps `DagOutputSchema` nodes and saves `LearningTrack` linked to user ID. |
| `TC-AGT-02` | Syllabus skill structure parsing | `SyllabusAnalyzerPipeline.generateTreeFromText` | **PASS** | Parses prerequisite titles and skill descriptions into `ExtractedSkill` objects. |
| `TC-AGT-03` | Flashcard Q&A extraction | `FlashcardGeneratorPipeline.generateFlashcards` | **PASS** | Extracts `frontQuestion` and `backAnswer` structures. |
| `TC-AGT-04` | English translation enforcement | `SyllabusAnalyzerPipeline` System Message | **PASS** | Prompt instructions contain explicit translation rules for non-English transcripts. |
| `TC-AGT-05` | LLM timeout & retry configuration | `LlmConfig.geminiModel` | **PASS** | Max retries set to 3 to absorb intermittent Google Gemini API rate limits. |

---

## Recommendations & Remediation Plan

1. **Implement Fallback Mock Model**: Create a fallback `ChatLanguageModel` bean that returns pre-formatted response templates if the primary Gemini model returns 401/429/500 errors.
2. **DAG Cycle Prevention Validation**: Add a graph validation check using Kahn's algorithm or Depth-First Search (DFS) in `DagGeneratorPipeline` before persisting to database to guarantee zero DAG cycles.
