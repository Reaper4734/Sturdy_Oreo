# Oreo: End-to-End User Flow Journey

This document outlines exactly how the user will experience the application, mapping their journey directly to the backend architecture and Hackathon Rubric. Hand this to the UI/UX developer.

---

### Phase 1: Onboarding & The Interview
1. **Login:** The user opens the app and signs in with Google. (Backend creates a `User` profile with 0 Points and a 0-day Streak).
2. **The Diagnostic Chat:** The app opens to a conversational chat interface. The AI asks: *"What do you want to learn, and how much time do you have?"*
3. **The Input:** The user types: *"I want to learn AWS Basics, but I only have 5 hours a week."*

### Phase 2: Agentic Orchestration (The "Wow" Moment)
4. **The Loading Screen:** The user hits **"Generate My Plan"**. The UI locks down with a beautiful, full-screen loading animation that says: *"Agent is analyzing your goals and searching the web..."*
5. **The Backend Engine (Invisible to User):** 
   * Our `ChatSummarizer` extracts their goals. 
   * Our `PlannerAssistant` designs a curriculum. 
   * Our `YouTubeSearchTool` autonomously searches Google for real video tutorials and weaves the URLs into the JSON syllabus.

### Phase 3: The Dynamic Dashboard
6. **The Reveal:** The loading screen fades, revealing a stunning, customized roadmap (rendered from our JSONB `LearningPlan`).
7. **Task Execution:** The user sees **Milestone 1**. Inside are specific tasks with time estimates (e.g., *"Watch: Intro to S3 - 20 mins"*). They click the task, and it opens the attached YouTube link.
8. **Gamification (The Dopamine Hit):** The user clicks the checkbox to complete the task. The UI flashes an animation: **"+50 Points! 1 Day Streak!"** *(Backend `GamificationController` safely increments their score and logs their `lastActiveDate`)*.

### Phase 4: The Active Feedback Loop (The Clincher)
9. **The Quiz:** The user finishes a milestone and clicks *"Test My Knowledge"*. The AI instantly generates a 5-question stateless assessment (MCQs + Subjective typing).
10. **The Instant Micro-Lesson:** The user gets an MCQ wrong. The UI **instantly** pops up a red tooltip containing the AI's explanation of exactly why they were wrong.
11. **The Grading Failure:** The user types a bad answer for a subjective question. They submit it. A dialog appears: *"Score: 40% - Failed. You said X, but the answer is Y."*
12. **The Agentic Remedial (The Magic Trick):** The user dismisses the failure dialog and goes back to their dashboard. **Like magic, a brand new task has appeared directly under the quiz they just failed.** It says: `[Remedial] Review: IAM Policies`, complete with a fresh YouTube link explicitly targeting their weak spot. *(This was our silent background `/adapt` API).*

### Phase 5: Time Management & Retention
13. **Smart Rescheduling:** Life gets busy. The user falls behind and misses deadlines. They tap a "Reschedule" button. The backend mathematically shifts all their incomplete deadlines forward by 2 days so they don't feel overwhelmed.
14. **The Nudge (Demo Simulation):** During the hackathon demo, you press a hidden "Simulate 3 Days Inactivity" button. A native mobile Push Notification pops up on the phone with a custom AI motivational message, proving you built the retention requirement.
