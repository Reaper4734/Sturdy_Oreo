---
name: spring-boot
description: Guides Spring Boot 3.x development with Java 21 for the Oreo platform. Covers project scaffolding, REST controllers, JPA repositories, WebSocket config, Flyway migrations, security setup, and LangChain4j integration.
---

# Spring Boot Development Skill (Oreo Backend)

## Project Context
- **Java**: 21 (Temurin)
- **Framework**: Spring Boot 3.x
- **Build Tool**: Gradle (Kotlin DSL - `build.gradle.kts`)
- **Database**: PostgreSQL 16 with pgvector extension
- **AI Integration**: LangChain4j for LLM orchestration
- **Auth**: Spring Security + JWT + Google OAuth2
- **Real-Time**: STOMP over WebSocket (Spring WebSocket)
- **Migrations**: Flyway
- **Testing**: JUnit 5, Mockito, Testcontainers

## Architecture Rules

### Layer Structure (Dependencies Point Inward Only)
```
Controller → Service → Repository → Database
                 ↘ OrchestrationService → LangChain4j Pipeline → LLM
```

### Code Conventions
1. **Controllers** are thin — no business logic, only request mapping + validation.
2. **Services** contain all business rules.
3. **Never expose JPA entities in API responses** — always map to DTOs.
4. **Use constructor injection** (not `@Autowired` field injection).
5. **Use SLF4J logging** — never `System.out.println`.
6. **Use `record` classes** for DTOs (Java 21 feature).
7. **Use `Optional`** for nullable return types from repositories.

### Package Structure
```
com.oreo/
├── auth/           # AuthController, AuthService, JwtService, SecurityConfig
├── track/          # TrackController, TrackService, TrackNode model
├── chat/           # ChatController, ChatService, WebSocketConfig
├── quiz/           # QuizController, QuizService
├── content/        # ContentController, ContentService
├── watchdog/       # WatchdogScheduler, HeartbeatService, InterventionDispatcher
├── orchestration/  # OrchestrationService, Pipeline implementations, LlmConfig
├── rag/            # RagService, ContentDiscoveryService, EmbeddingService
├── persona/        # PersonaService, PersonaRecalibrationService
├── analytics/      # PeerAnalyticsService, ScheduleService
├── common/         # GlobalExceptionHandler, DTOs, AppConstants
└── config/         # SecurityConfig, WebSocketConfig, CorsConfig
```

### API Response Pattern
```java
// Success
ResponseEntity.ok(new TrackResponse(track));

// Error (via GlobalExceptionHandler)
ResponseEntity.status(503).body(new ErrorResponse("AI_UNAVAILABLE", "Retry in a moment"));
```

### Database Conventions
- Table names: `snake_case` (e.g., `learning_tracks`, `chat_history`)
- Primary keys: `UUID` (generated via `gen_random_uuid()`)
- Timestamps: Always include `created_at` and `updated_at`
- JSONB columns: Use `@Convert(converter = JsonbConverter.class)`

## Key Dependencies (build.gradle.kts)
```kotlin
dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-websocket")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.0")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    implementation("org.postgresql:postgresql")
    implementation("dev.langchain4j:langchain4j-spring-boot-starter:1.0.1")
    implementation("dev.langchain4j:langchain4j-google-ai-gemini:1.0.1")
    implementation("io.jsonwebtoken:jjwt-api:0.12.6")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.6")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.6")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.testcontainers:postgresql")
}
```

## References
- Module specs: M5 (Java Core Engine), M6 (AI Orchestration), M7 (RAG Pipeline), M8 (Data Persistence)
- Location: `c:\CP\Oreo\M5_java_core_engine.md` through `M8_data_persistence.md`
