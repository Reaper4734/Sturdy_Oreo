# Technical Audit Report: JSON Context & Schema Consistency

**Target Component**: DTO Contracts, Jackson Serialization & LangChain4j Schema Mapping  
**Module Reference**: `com.oreo.engine.orchestration.schemas`  
**Reviewer Role**: Senior Code Reviewer & Data Engineer  
**Audit Date**: July 24, 2026  

---

## Executive Summary

This report evaluates JSON context propagation, serialization fidelity, and schema consistency across REST endpoints, WebSocket payloads, and LLM structured outputs in the **Oreo Platform**.

---

## Schema Architecture & Contract Alignment

### 1. `DagOutputSchema` (`com.oreo.engine.orchestration.schemas.DagOutputSchema`)
- **JSON Property Mappings**:
  - `track_id` $\rightarrow$ `String trackId`
  - `goal` $\rightarrow$ `String goal`
  - `nodes` $\rightarrow$ `List<DagNode> nodes`
- **Inner Node Structure**:
  - `id`: Unique identifier (e.g. `n1`)
  - `title`: Node heading
  - `type`: Content modality (`visual_theory`, `interactive`, `article`, `documentation`)
  - `prereqs`: List of parent node IDs
  - `rationale`: 1-sentence motivation
  - `alternatives`: Swappable topic alternatives

### 2. `ProfilerOutputSchema` (`com.oreo.engine.orchestration.schemas.ProfilerOutputSchema`)
- **JSON Property Mappings**:
  - `reply_to_user` $\rightarrow$ `String replyToUser`
  - `internal_state` $\rightarrow$ `InternalState internalState`
- **Internal State Object**:
  - `domain_identified`: boolean
  - `eq_identified`: boolean
  - `modality_identified`: boolean
  - `confidence_score`: integer (0-100)
  - `current_inferred_persona`: `InferredPersona` (`domain`, `iq_logic`, `eq_resilience`)

---

## Technical Audit Findings

> [!NOTE]
> **Jackson Naming Policy Consistency**: Jackson `@JsonProperty` annotations explicitly enforce `snake_case` in JSON payloads while maintaining standard `camelCase` fields in Java POJOs. This guarantees compatibility with Python/TypeScript frontend clients.

> [!WARNING]
> **Missing Null Checks on Optional Inner Objects**:
> In `ProfilerOutputSchema`, if the LLM returns `"internal_state": null`, direct callers accessing `schema.getInternalState().isDomainIdentified()` will throw a `NullPointerException`. Controllers MUST check for null `internalState`.

---

## Test Cases & Verification Results

| Test ID | Test Description | Target Method | Status | Findings / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `TC-JSON-01` | `DagOutputSchema` Jackson deserialization | `JsonSchemaValidationTest.shouldDeserializeDagOutputSchemaCorrectly` | **PASS** | Correctly maps `track_id`, `goal`, `prereqs`, `rationale`, and `alternatives`. |
| `TC-JSON-02` | `ProfilerOutputSchema` Jackson deserialization | `JsonSchemaValidationTest.shouldDeserializeProfilerOutputSchemaCorrectly` | **PASS** | Successfully deserializes nested `internal_state` and boolean flags. |
| `TC-JSON-03` | Null handling in schema payloads | `JsonSchemaValidationTest.shouldHandlePartialOrNullJsonFieldsInProfilerOutputSchema` | **PASS** | Deserializes partial JSON without throwing deserialization exceptions. |
| `TC-JSON-04` | Standard error JSON payload contract | `OreoExceptionHandler` / API contract | **PASS** | Returns uniform `{ error, message, timestamp, traceId }` JSON error responses. |

---

## Recommendations & Remediation Plan

1. **Add Lombok `@Builder.Default` or Null-Safe Accessors**: Provide defensive getters (e.g. `public InternalState getInternalState() { return internalState != null ? internalState : new InternalState(); }`).
2. **Schema Validation Filter**: Integrate `@Valid` and Bean Validation constraints (`@NotNull`, `@Min(0)`, `@Max(100)`) on incoming JSON DTO controllers.
