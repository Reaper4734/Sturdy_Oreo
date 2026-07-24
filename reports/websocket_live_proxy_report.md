# Technical Audit Report: WebSocket Architecture & Gemini Live Proxy

**Target Component**: Real-time STOMP Messaging & Multimodal Live WebSocket Handler  
**Module Reference**: `com.oreo.config.WebSocketConfig` / `com.oreo.engine.orchestration.controller.GeminiLiveProxyWebSocketHandler`  
**Reviewer Role**: Senior Code Reviewer & System Architect  
**Audit Date**: July 24, 2026  
**Status**: **FIXED & SECURED** (100% Test Pass Rate)

---

## Executive Summary

The WebSocket subsystem in **Oreo** handles two concurrent communication patterns:
1. **STOMP over WebSocket** (`/ws/orchestration`): Structured message broker handling student chat, canvas visualization frames, DAG updates, and intervention quizzes.
2. **Raw Multimodal Live Proxy** (`/ws/live`): Low-latency WebSocket handler proxying raw PCM audio bytes between client sessions and Google Gemini's Multimodal Live API (`wss://generativelanguage.googleapis.com/...`).

---

## Detailed Architectural Analysis & Fixes Applied

### 1. STOMP Message Broker & SUBSCRIBE Authorization (`WebSocketConfig.java`)
- **Broker Prefix**: Simple in-memory broker on `/topic` and `/queue`.
- **Application Destination**: `/app` for client-to-server messaging (`/app/chat.send`).
- **Security Interceptors Applied**:
  - `CONNECT`: Extracts `Authorization: Bearer <JWT>` header, validates via `JwtService`, and populates Spring Security `UsernamePasswordAuthenticationToken`.
  - `SUBSCRIBE` (**APPLIED FIX**): Intercepts destination topics (`/topic/session/user/{targetUserId}/**`) and verifies that the authenticated user matches the topic target user ID. Rejects unauthorized topic subscription attempts with `AccessDeniedException`.

### 2. Gemini Multimodal Live Proxy & Null Safety (`GeminiLiveProxyWebSocketHandler.java`)
- **Query Parameter Parsing**: Extracts `roomId`, `videoId`, and `timestamp` from `/ws/live` connection query string.
- **Null Pointer Fix (**APPLIED FIX**)**: Added `if (roomId != null)` check before looking up `roomGeminiSessions.get(roomId)`. Prevents `ConcurrentHashMap.get(null)` NullPointerException when unregistered client sessions send WebSocket frames.

---

## Test Cases & Verification Results

| Test ID | Test Description | Target Method | Status | Findings / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `TC-WS-01` | STOMP `CONNECT` JWT authentication | `WebSocketConfig.configureClientInboundChannel` | **PASS** | Validates Bearer token and sets SecurityContext User. |
| `TC-WS-02` | Live Proxy URI query parameter parsing | `GeminiLiveProxyWebSocketHandler.afterConnectionEstablished` | **PASS** | Correctly parses `roomId`, `videoId`, and `timestamp`. |
| `TC-WS-03` | Room disconnection cleanup | `GeminiLiveProxyWebSocketHandler.afterConnectionClosed` | **PASS** | Closes Gemini WSS connection when last client leaves room. |
| `TC-WS-04` | Unregistered session message safety | `GeminiLiveProxyWebSocketHandler.handleTextMessage` | **PASS** | `roomId != null` safety check prevents NPE on unmapped sessions. |
| `TC-WS-05` | Binary audio payload multiplexing | `GeminiLiveProxyWebSocketHandler.handleBinaryMessage` | **PASS** | Binary audio payload forwarding verified; multi-client rooms recommended Push-to-Talk. |
