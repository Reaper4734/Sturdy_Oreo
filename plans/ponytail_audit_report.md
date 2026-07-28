# 🐴 Ponytail Audit: Frontend-Backend Integration

As requested, I've audited the frontend-backend integration for flaws, data leaks, mismatched connections, and directory structure anomalies. 

## Ponytail Over-Engineering Audit (Biggest Cuts First)

- `delete` `LearningPathController`, `SyllabusAnalyzerPipeline`, `SkillNode` entities. Replaced by `OrchestrationController` and `DagGeneratorPipeline` for `/dag-generate`. [backend/src/main/java/com/oreo/engine/orchestration/controller/LearningPathController.java]
- `delete` `FlashcardController` (brittle regex parsing). Replaced by the structured JSON generation already functioning in `AssessmentController` (`/assessments/flashcards`). [backend/src/main/java/com/oreo/engine/orchestration/controller/FlashcardController.java]
- `shrink` `DashboardController` and its massive `DashboardProfileSchema` DTO. Replaced by existing frontend `HttpDashboardRepository` mock data until actual database tracking is built. [backend/src/main/java/com/oreo/engine/orchestration/controller/DashboardController.java]
- `delete` `SpacedRepetitionService`. A dead cron job running daily that just prints a log message. [backend/src/main/java/com/oreo/engine/orchestration/SpacedRepetitionService.java]

*Net lines removable: ~550 lines of dead/speculative code.*

---

## 🚨 Security & Data Leaks
- **Hardcoded JWT Dev Token**: In `frontend/lib/core/api_client.dart`, `ApiClient` has a hardcoded static `devToken`. 
  > [!CAUTION]
  > This JWT is checked into source control. If this was a production token, this would be a critical data leak.

## 🔌 Mismatched Connections
- **The Dashboard Illusion**: The frontend's `HttpDashboardRepository` makes a real HTTP request to `/api/dashboard/profile`. However, the backend `DashboardController` just generates hardcoded strings and a random heatmap (e.g. `Random().nextInt(100)`). It's essentially mocking a mock, making the HTTP call completely redundant.
- **Dueling Flashcard APIs**: The backend exposes two different AI flashcard endpoints. The frontend uses `/api/orchestration/assessments/flashcards` (which is correctly typed), leaving the older `FlashcardController` endpoints completely orphaned.

## 📂 Directory Structure Flaws
- **`model` vs `models`**: The backend `orchestration` package contains both a `model` and a `models` directory. 
- **Repository Placement**: Inside the `models` directory sits `LearningTrackRepository.java`. It belongs in the `repository` package, not mixed in with entities.
