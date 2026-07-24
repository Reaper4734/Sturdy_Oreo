# Technical Audit Report: Auth, Security & Session Persistence

**Target Component**: JWT Authentication, Spring Security, Watchdog Session Daemon & Spaced Repetition  
**Module Reference**: `com.oreo.auth` / `com.oreo.config.SecurityConfig` / `com.oreo.engine.watchdog`  
**Reviewer Role**: Senior Security & Backend Engineer  
**Audit Date**: July 24, 2026  

---

## Executive Summary

This report analyzes the security posture, authentication token lifecycle, Spring Security filter chain, background session watchdog monitoring, and SuperMemo-2 (SM-2) spaced repetition algorithm implementation in **Oreo**.

---

## Detailed Component Analysis

### 1. JWT Authentication Service (`JwtService.java`)
- **Key Signing**: HMAC-SHA256 using 256-bit secret key.
- **Claims**: Stores `userId` (UUID) and `email` (String) inside token subject and claims.
- **Expiration**: Standard 1-hour expiration period (`3600000 ms`).
- **Validation**: Verifies signature integrity, token format, and expiration timestamp.

### 2. Spring Security Configuration (`SecurityConfig.java`)
- **Stateless Session Management**: Configured with `SessionCreationPolicy.STATELESS`.
- **Public Routes**:
  - `/auth/**` (Registration, Login, Google Auth)
  - `/ws/**` (WebSocket Endpoints)
  - `/actuator/**` (Health metrics)
  - `/swagger-ui/**`, `/v3/api-docs/**` (OpenAPI documentation)
- **Protected Routes**: `/api/**` requires valid Bearer JWT.

### 3. Watchdog Daemon & Idle Session Monitoring (`WatchdogDaemon.java`)
- **Session Manager**: `WatchdogSessionManager` tracks active user heartbeats via `ConcurrentHashMap<String, Instant>`.
- **Threshold**: Sessions inactive for over 180 seconds are flagged as `IDLE`.
- **Intervention Trigger**: Calls `SmartNudgePipeline` to generate an interactive quiz or motivational nudge and pushes payload via WebSocket to `/topic/session/{id}/interventions`.

### 4. Spaced Repetition Algorithm (`SpacedRepetitionService.java`)
- **Algorithm**: SuperMemo-2 (SM-2) implementation.
- **Quality Scale**: 0 = Total blackout, 3 = Hard, 4 = Good, 5 = Perfect.
- **Mathematical Formulae**:
  - If Quality $< 3$:
    $$\text{Consecutive Correct} = 0, \quad \text{Interval Days} = 1$$
  - If Quality $\ge 3$:
    $$\text{Consecutive Correct} = c + 1$$
    $$\text{Interval Days} = \begin{cases} 1 & \text{if } c=1 \\ 6 & \text{if } c=2 \\ \text{Round}(\text{Interval} \times \text{Ease Factor}) & \text{if } c > 2 \end{cases}$$
  - Ease Factor Update:
    $$\text{EF}' = \text{EF} + (0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02))$$
    $$\text{EF}' = \max(\text{EF}', 1.3)$$

---

## Technical Audit Findings

> [!NOTE]
> **SM-2 Algorithm Correctness**: Unit tests confirm that Ease Factor never drops below the absolute floor of 1.3, preventing interval compression collapse for difficult flashcards.

> [!IMPORTANT]
> **Watchdog Heartbeat Reset Verification**: When an idle session receives a nudge intervention, `WatchdogDaemon` updates the session timestamp to prevent spamming duplicate interventions every scan cycle.

---

## Test Cases & Verification Results

| Test ID | Test Description | Target Method | Status | Findings / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `TC-AUTH-01` | JWT Generation and Validation | `JwtServiceTest.shouldGenerateAndValidateToken` | **PASS** | Successfully generates signed token, validates signature, and extracts `userId`. |
| `TC-AUTH-02` | Invalid JWT rejection | `JwtServiceTest.shouldReturnFalseForInvalidToken` | **PASS** | Rejects malformed or corrupted token strings. |
| `TC-WD-01` | Active session scan | `WatchdogDaemonTest.scanForIdleSessions_ShouldNotNudge_WhenSessionIsActive` | **PASS** | Does not trigger nudge when session heartbeat is fresh (< 180s). |
| `TC-WD-02` | Idle session intervention | `WatchdogDaemonTest.scanForIdleSessions_ShouldTriggerNudge_WhenSessionIsIdle` | **PASS** | Triggers `SmartNudgePipeline` and broadcasts to intervention WebSocket channel when session > 180s idle. |
| `TC-SM2-01` | SM-2 incorrect answer reset | `SpacedRepetitionAndWatchdogTest.reviewCard_ShouldResetIntervalAndConsecutive_WhenQualityIsBelow3` | **PASS** | Resets consecutive correct answers to 0 and interval to 1 day for quality < 3. |
| `TC-SM2-02` | SM-2 interval expansion | `SpacedRepetitionAndWatchdogTest.reviewCard_ShouldProgressInterval_WhenQualityIs5` | **PASS** | Increases interval to 6 days and increments ease factor by 0.1 for quality 5. |
| `TC-SM2-03` | SM-2 ease factor floor | `SpacedRepetitionAndWatchdogTest.reviewCard_ShouldEnforceMinimumEaseFactorFloorOf1Point3` | **PASS** | Clamps ease factor at minimum value of 1.3. |

---

## Recommendations & Remediation Plan

1. **Token Blacklisting / Revocation**: Add a Redis or database token revocation store for instant logout invalidation prior to JWT expiry.
2. **Cron Schedule Optimization**: Ensure `@Scheduled(cron = "0 0 8 * * ?")` in `SpacedRepetitionService` uses a distributed lock (e.g. ShedLock) if running multiple backend server instances.
