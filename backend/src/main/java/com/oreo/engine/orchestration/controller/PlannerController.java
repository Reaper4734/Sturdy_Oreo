package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.model.LearningPlan;
import com.oreo.engine.orchestration.pipelines.PlannerAssistant;
import com.oreo.engine.orchestration.pipelines.ChatSummarizer;
import com.oreo.engine.orchestration.repository.LearningPlanRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/orchestration/planner")
public class PlannerController {

    private final PlannerAssistant plannerAssistant;
    private final ChatSummarizer chatSummarizer;
    private final LearningPlanRepository learningPlanRepository;

    public PlannerController(PlannerAssistant plannerAssistant, ChatSummarizer chatSummarizer,
            LearningPlanRepository learningPlanRepository) {
        this.plannerAssistant = plannerAssistant;
        this.chatSummarizer = chatSummarizer;
        this.learningPlanRepository = learningPlanRepository;
    }

    private UUID resolveUserId(String userId) {
        if (userId != null && !userId.isBlank() && !"anonymousUser".equalsIgnoreCase(userId)) {
            try {
                return UUID.fromString(userId);
            } catch (IllegalArgumentException e) {
                return UUID.nameUUIDFromBytes(userId.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            }
        }
        return UUID.fromString("00000000-0000-0000-0000-000000000001");
    }

    @PostMapping("/generate")
    public ResponseEntity<LearningPlan> generatePlan(
            @AuthenticationPrincipal String userId,
            @RequestBody Map<String, String> payload) {

        String chatTranscript = payload.getOrDefault("chatTranscript", payload.getOrDefault("learningGoal", "General Software Engineering"));

        // 0. Fix Token Bloat: Summarize the chat first
        String goalSummary = chatSummarizer.summarize(chatTranscript);

        // 1. Agent generates the JSON structure using the summarized goal
        LearningPlan.PlanData planData = plannerAssistant.generatePlan(goalSummary);

        // 2. Wrap it in the Entity and Save
        UUID userUuid = resolveUserId(userId);
        LearningPlan plan = learningPlanRepository.findByUserId(userUuid)
                .orElseGet(() -> {
                    LearningPlan newPlan = new LearningPlan();
                    newPlan.setUserId(userUuid);
                    return newPlan;
                });

        plan.setGoalStatement(goalSummary);
        plan.setPlanData(planData);

        LearningPlan savedPlan = learningPlanRepository.save(plan);
        return ResponseEntity.ok(savedPlan);
    }

    @GetMapping("/")
    public ResponseEntity<LearningPlan> getPlan(@AuthenticationPrincipal String userId) {
        UUID userUuid = resolveUserId(userId);
        return learningPlanRepository.findByUserId(userUuid)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/task/{taskId}/complete")
    public ResponseEntity<LearningPlan> completeTask(
            @AuthenticationPrincipal String userId,
            @PathVariable String taskId,
            @RequestBody Map<String, Integer> payload) {

        UUID userUuid = resolveUserId(userId);
        LearningPlan plan = learningPlanRepository.findByUserId(userUuid)
                .orElse(null);
        if (plan == null) {
            return ResponseEntity.notFound().build();
        }

        int timeSpent = payload.getOrDefault("actualTimeSpentMinutes", 0);

        // Clean, surgical traversal using Optionals and Streams (No ugly null-nesting)
        java.util.Optional.ofNullable(plan.getPlanData())
                .map(LearningPlan.PlanData::getMilestones)
                .ifPresent(milestones -> milestones.stream()
                        .filter(m -> m.getTasks() != null)
                        .flatMap(m -> m.getTasks().stream())
                        .filter(t -> taskId.equals(t.getId()))
                        .findFirst()
                        .ifPresent(task -> {
                            task.setCompleted(true);
                            task.setActualTimeSpentMinutes(timeSpent);
                        }));

        return ResponseEntity.ok(learningPlanRepository.save(plan));
    }

    @PostMapping("/adapt")
    public ResponseEntity<LearningPlan> adaptPlan(
            @AuthenticationPrincipal String userId,
            @RequestBody Map<String, String> payload) {

        UUID userUuid = resolveUserId(userId);
        LearningPlan plan = learningPlanRepository.findByUserId(userUuid)
                .orElse(null);
        if (plan == null) {
            return ResponseEntity.notFound().build();
        }

        String failedQuestion = payload.get("failedQuestion");
        String userAnswer = payload.get("userAnswer");
        String failedTaskId = payload.get("failedTaskId");

        String context = String.format("Question: %s\nUser's incorrect answer: %s", failedQuestion, userAnswer);

        // 1. True Agentic Generation
        LearningPlan.Task remedialTask = plannerAssistant.generateRemedialTask(context);

        // 2. Fix LLM Hallucinations
        remedialTask.setId(UUID.randomUUID().toString());
        remedialTask.setCompleted(false);
        if (remedialTask.getTitle() != null && !remedialTask.getTitle().startsWith("[Remedial]")) {
            remedialTask.setTitle("[Remedial] " + remedialTask.getTitle());
        }

        // 3. Smart Injection Logic
        LearningPlan.PlanData data = plan.getPlanData();
        if (data != null && data.getMilestones() != null && !data.getMilestones().isEmpty()) {
            java.util.List<LearningPlan.Milestone> milestones = data.getMilestones();

            LearningPlan.Milestone targetMilestone = null;
            int insertIndex = -1;

            if (failedTaskId != null) {
                for (LearningPlan.Milestone m : milestones) {
                    if (m.getTasks() != null) {
                        for (int i = 0; i < m.getTasks().size(); i++) {
                            if (failedTaskId.equals(m.getTasks().get(i).getId())) {
                                targetMilestone = m;
                                insertIndex = i + 1;
                                break;
                            }
                        }
                    }
                    if (targetMilestone != null)
                        break;
                }
            }

            if (targetMilestone == null) {
                targetMilestone = milestones.stream()
                        .filter(m -> m.getTasks() != null
                                && m.getTasks().stream().anyMatch(t -> !t.isCompleted()))
                        .findFirst()
                        .orElse(milestones.get(milestones.size() - 1));
                insertIndex = targetMilestone.getTasks() != null ? targetMilestone.getTasks().size() : 0;
            }

            if (targetMilestone.getTasks() == null) {
                targetMilestone.setTasks(new java.util.ArrayList<>());
                insertIndex = 0;
            }
            targetMilestone.getTasks().add(insertIndex, remedialTask);
        }

        LearningPlan savedPlan = learningPlanRepository.save(plan);
        return ResponseEntity.ok(savedPlan);
    }

    @PostMapping("/reschedule")
    public ResponseEntity<LearningPlan> reschedulePlan(@AuthenticationPrincipal String userId) {
        UUID userUuid = resolveUserId(userId);
        LearningPlan plan = learningPlanRepository.findByUserId(userUuid)
                .orElse(null);
        if (plan == null) {
            return ResponseEntity.notFound().build();
        }

        // Shift all incomplete task deadlines forward by 2 days.
        java.util.Optional.ofNullable(plan.getPlanData())
                .map(LearningPlan.PlanData::getMilestones)
                .ifPresent(milestones -> milestones.stream()
                        .filter(m -> m.getTasks() != null)
                        .flatMap(m -> m.getTasks().stream())
                        .filter(t -> !t.isCompleted() && t.getDeadlineDate() != null)
                        .forEach(t -> t.setDeadlineDate(t.getDeadlineDate().plusDays(2))));

        return ResponseEntity.ok(learningPlanRepository.save(plan));
    }
}
