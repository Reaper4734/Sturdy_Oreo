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

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/orchestration/planner")
public class PlannerController {

    private final PlannerAssistant plannerAssistant;
    private final ChatSummarizer chatSummarizer;
    private final LearningPlanRepository learningPlanRepository;

    public PlannerController(ChatLanguageModel chatLanguageModel, YouTubeSearchTool youTubeSearchTool, LearningPlanRepository learningPlanRepository) {
        this.learningPlanRepository = learningPlanRepository;
        this.chatSummarizer = AiServices.builder(ChatSummarizer.class)
                .chatLanguageModel(chatLanguageModel)
                .build();
        this.plannerAssistant = AiServices.builder(PlannerAssistant.class)
                .chatLanguageModel(chatLanguageModel)
                .tools(youTubeSearchTool)
                .build();
    }

    @PostMapping("/generate")
    public ResponseEntity<LearningPlan> generatePlan(
            @AuthenticationPrincipal String userId,
            @RequestBody Map<String, String> payload) {
            
        String chatTranscript = payload.get("chatTranscript");
        
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
        
        return ResponseEntity.ok(learningPlanRepository.save(plan));
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
}
