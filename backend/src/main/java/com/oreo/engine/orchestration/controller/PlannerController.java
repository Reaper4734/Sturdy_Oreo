package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.model.LearningPlan;
import com.oreo.engine.orchestration.pipelines.PlannerAssistant;
import com.oreo.engine.orchestration.pipelines.ChatSummarizer;
import com.oreo.engine.orchestration.repository.LearningPlanRepository;
import com.oreo.engine.orchestration.tools.YouTubeSearchTool;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/api/orchestration/planner")
public class PlannerController {

    private final PlannerAssistant plannerAssistant;
    private final ChatSummarizer chatSummarizer;
    private final LearningPlanRepository learningPlanRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public PlannerController(PlannerAssistant plannerAssistant, ChatSummarizer chatSummarizer, LearningPlanRepository learningPlanRepository, SimpMessagingTemplate messagingTemplate) {
        this.plannerAssistant = plannerAssistant;
        this.chatSummarizer = chatSummarizer;
        this.learningPlanRepository = learningPlanRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @PostMapping("/generate")
    public ResponseEntity<Map<String, String>> generatePlan(
            @AuthenticationPrincipal String userId,
            @RequestBody Map<String, String> payload) {
            
        String chatTranscript = payload.get("chatTranscript");
        
        CompletableFuture.runAsync(() -> {
            try {
                // 0. Fix Token Bloat: Summarize the chat first
                String goalSummary = chatSummarizer.summarize(chatTranscript);
                
                // 1. Agent generates the JSON structure using the summarized goal
                LearningPlan.PlanData planData = plannerAssistant.generatePlan(goalSummary);
                
                // 2. Wrap it in the Entity and Save
                LearningPlan plan = learningPlanRepository.findByUserId(UUID.fromString(userId))
                        .orElseGet(() -> {
                            LearningPlan newPlan = new LearningPlan();
                            newPlan.setUserId(UUID.fromString(userId));
                            return newPlan;
                        });
                        
                plan.setGoalStatement("Parsed from transcript");
                plan.setPlanData(planData);
                
                LearningPlan savedPlan = learningPlanRepository.save(plan);
                messagingTemplate.convertAndSend("/topic/session/user/" + userId + "/plan", savedPlan);
            } catch (Exception e) {
                messagingTemplate.convertAndSend("/topic/session/user/" + userId + "/error", Map.of("error", e.getMessage()));
            }
        });
        
        return ResponseEntity.accepted().body(Map.of("status", "processing", "message", "Plan generation started asynchronously."));
    }
    
    @GetMapping("/")
    public ResponseEntity<LearningPlan> getPlan(@AuthenticationPrincipal String userId) {
        return learningPlanRepository.findByUserId(UUID.fromString(userId))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    @PutMapping("/task/{taskId}/complete")
    public ResponseEntity<LearningPlan> completeTask(
            @AuthenticationPrincipal String userId,
            @PathVariable String taskId,
            @RequestBody Map<String, Integer> payload) {
            
        LearningPlan plan = learningPlanRepository.findByUserId(UUID.fromString(userId))
                .orElseThrow(() -> new RuntimeException("Plan not found"));
                
        int timeSpent = payload.getOrDefault("actualTimeSpentMinutes", 0);
        
        if (plan.getPlanData() != null && plan.getPlanData().getMilestones() != null) {
            for (LearningPlan.Milestone m : plan.getPlanData().getMilestones()) {
                if (m.getTasks() != null) {
                    for (LearningPlan.Task t : m.getTasks()) {
                        if (taskId.equals(t.getId())) {
                            t.setCompleted(true);
                            t.setActualTimeSpentMinutes(timeSpent);
                            break;
                        }
                    }
                }
            }
        }
        
        return ResponseEntity.ok(learningPlanRepository.save(plan));
    }

    @PostMapping("/adapt")
    public ResponseEntity<Map<String, String>> adaptPlan(
            @AuthenticationPrincipal String userId,
            @RequestBody Map<String, String> payload) {
            
        CompletableFuture.runAsync(() -> {
            try {
                LearningPlan plan = learningPlanRepository.findByUserId(UUID.fromString(userId))
                        .orElseThrow(() -> new RuntimeException("Plan not found"));
                        
                String failedQuestion = payload.get("failedQuestion");
                String userAnswer = payload.get("userAnswer");
                String failedTaskId = payload.get("failedTaskId");
                
                String context = String.format("Question: %s\nUser's incorrect answer: %s", failedQuestion, userAnswer);
                
                // 1. True Agentic Generation (Takes ~10 seconds)
                LearningPlan.Task remedialTask = plannerAssistant.generateRemedialTask(context);
                
                // 2. Fix LLM Hallucinations (Security)
                remedialTask.setId(UUID.randomUUID().toString());
                remedialTask.setCompleted(false);
                if (remedialTask.getTitle() != null && !remedialTask.getTitle().startsWith("[Remedial]")) {
                    remedialTask.setTitle("[Remedial] " + remedialTask.getTitle());
                }
                
                // 3. Smart Injection Logic
                LearningPlan.PlanData data = plan.getPlanData();
                if (data != null && data.getMilestones() != null && !data.getMilestones().isEmpty()) {
                    LearningPlan.Milestone m = data.getMilestones().get(0);
                    if (m.getTasks() == null) {
                        m.setTasks(new java.util.ArrayList<>());
                    }
                    m.getTasks().add(remedialTask);
                }
                
                LearningPlan savedPlan = learningPlanRepository.save(plan);
                messagingTemplate.convertAndSend("/topic/session/user/" + userId + "/plan", savedPlan);
            } catch (Exception e) {
                messagingTemplate.convertAndSend("/topic/session/user/" + userId + "/error", Map.of("error", e.getMessage()));
            }
        });
        
        return ResponseEntity.accepted().body(Map.of("status", "processing", "message", "Plan adaptation started asynchronously."));
    }

    @PostMapping("/reschedule")
    public ResponseEntity<LearningPlan> reschedulePlan(@AuthenticationPrincipal String userId) {
        LearningPlan plan = learningPlanRepository.findByUserId(UUID.fromString(userId))
                .orElseThrow(() -> new RuntimeException("Plan not found"));
        
        // MVP Hackathon Logic: Shift all incomplete task deadlines forward by 2 days.
        if (plan.getPlanData() != null && plan.getPlanData().getMilestones() != null) {
            for (LearningPlan.Milestone m : plan.getPlanData().getMilestones()) {
                if (m.getTasks() != null) {
                    for (LearningPlan.Task t : m.getTasks()) {
                        if (!t.isCompleted() && t.getDeadlineDate() != null) {
                            t.setDeadlineDate(t.getDeadlineDate().plusDays(2));
                        }
                    }
                }
            }
        }

        return ResponseEntity.ok(learningPlanRepository.save(plan));
    }
}
