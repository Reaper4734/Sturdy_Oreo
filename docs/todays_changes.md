# Summary of Today's Changes

## 1. LLM Orchestration & Structured Output Fixes
- **LangChain4j POJO Reflection**: Resolved `ClassCastException: ParameterizedTypeImpl cannot be cast to Class` in `WorkspaceChatOutputSchema.java` by replacing generic `List<Map<String, Object>>` with a strongly-typed `RoadmapNodeDto` POJO.
- **Token Truncation Prevention**: Increased `maxOutputTokens` from `2048` to `8192` in `LlmConfig.java` and refined `WorkspaceChatPipeline.java` prompt to only return `updatedRoadmap` on explicit modification requests.
- **Gemini Model Alignment**: Standardized model references on `gemini-3.5-flash-lite`.

## 2. Decoupled Onboarding Interview vs. Learning Lab Workspace Chat
- **Explicit API Methods**: Added `sendInterviewMessage()` and `sendWorkspaceChatMessage()` in `HttpInterviewRepository.dart`.
- **Context Separation**: Added `isWorkspaceMode` flag to `MicroInterviewScreen.dart`. The Onboarding Interview exclusively routes to `/api/orchestration/interview`, while the Learning Lab sidebar routes to `/api/orchestration/workspace-chat`.

## 3. Real-Time Progressive Streaming Markdown & Typing Speed
- **On-The-Go Formatting**: Implemented `StreamingMarkdownBody` to replace `AnimatedTextKit`. Formatted Markdown elements (bold text, bulleted lists, numbered items, code blocks) now render live in real-time as words stream in, eliminating post-generation layout pops.
- **Optimized Typing Speed**: Scaled chunk streaming (3–16 characters every 12ms) to allow AI responses to stream naturally and finish within ~1 second.
- **Instant Skip**: Tapping any streaming message instantly completes the text.

## 4. Keyboard Shortcuts for Chatbot
- **Enter**: Sends the chat message immediately without inserting redundant newlines.
- **Shift + Enter**: Inserts a newline and moves the cursor downward for multiline typing.

## 5. Backend Startup & Database Resilience
- **PostgreSQL TCP Polling**: Enhanced `start_all.ps1` and `start_backend.ps1` to poll TCP port `5432` until PostgreSQL is actively accepting connections before Spring Boot boots up.
- **Docker Auto-Launch**: Automatically detects if the Docker daemon is stopped, launches Docker Desktop, and waits for initialization.
- **JVM Heap Allocation**: Configured `-Xmx2g` heap sizing for JAR execution to handle local embeddings.

## 6. YouTube Player & Workspace Video Loading
- **Unblocked Initialization**: Removed blocking condition `!activeWs.isCourseConfirmed` in `learning_lab_workspace_screen.dart` to allow instant video search and streaming.
- **Dynamic Controller Lifecycle**: Updated `youtube_player_widget.dart` with dynamic video loading and graceful placeholders.
