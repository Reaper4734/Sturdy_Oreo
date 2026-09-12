package com.oreo.engine.orchestration.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.oreo.auth.User;
import com.oreo.auth.UserRepository;
import com.oreo.engine.orchestration.model.Workspace;
import com.oreo.engine.orchestration.repository.WorkspaceRepository;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final UserRepository userRepository;
    private final WorkspaceRepository workspaceRepository;

    public DashboardController(UserRepository userRepository, WorkspaceRepository workspaceRepository) {
        this.userRepository = userRepository;
        this.workspaceRepository = workspaceRepository;
    }

    @GetMapping("/profile")
    public ResponseEntity<Map<String, Object>> getDashboardProfile(
            org.springframework.security.core.Authentication authentication,
            @org.springframework.web.bind.annotation.RequestParam(required = false) String workspaceId) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).build();
        }
        
        java.util.UUID userId = java.util.UUID.fromString(authentication.getPrincipal().toString());
        Optional<User> userOpt = userRepository.findById(userId);
        
        if (userOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        
        User user = userOpt.get();
        String learnerName = user.getDisplayName();
        int streak = user.getCurrentStreak();
        int xp = user.getTotalPoints();
        int level = xp / 100;

        java.util.Map<String, Object> responseMap = new java.util.HashMap<>();
        responseMap.put("learnerName", learnerName);
        responseMap.put("greetingInsight", "Let's keep up the great work!");
        responseMap.put("recommendation", "Continue your latest workspace.");
        responseMap.put("journey", Map.of(
                "overallProgress", 0.0,
                "level", level,
                "xp", xp,
                "streakDays", streak,
                "hoursLearned", 0,
                "hoursRemaining", 0
        ));
        responseMap.put("timelineEvents", List.of());
        responseMap.put("heatmapScores", generateHeatmap());
        
        // Populate continueLearning and workspaceSummary from the selected workspace
        List<Workspace> workspaces = workspaceRepository.findByUserId(userId);
        if (!workspaces.isEmpty()) {
            Workspace selected = null;
            if (workspaceId != null && !workspaceId.isEmpty()) {
                selected = workspaces.stream().filter(w -> w.getId().equals(workspaceId)).findFirst().orElse(null);
            }
            if (selected == null) {
                // fallback to most recently active or created
                selected = workspaces.stream().max(java.util.Comparator.comparing(w -> {
                    String lastOpened = (String) w.getData().getOrDefault("lastOpened", "");
                    return lastOpened.isEmpty() ? w.getCreatedAt().toString() : lastOpened;
                })).orElse(workspaces.get(0));
            }

            Map<String, Object> wsData = selected.getData();
            responseMap.put("continueLearning", Map.of(
                    "workspaceName", wsData.getOrDefault("title", ""),
                    "currentCourse", wsData.getOrDefault("activeLearningContext", ""),
                    "difficulty", wsData.getOrDefault("difficulty", ""),
                    "currentTopic", wsData.getOrDefault("activeLearningContext", ""),
                    "nextAction", "Continue",
                    "estimatedTime", "30m",
                    "progressPercent", wsData.getOrDefault("progressPercent", 0.0)
            ));
            responseMap.put("workspaceSummary", Map.of(
                    "workspaceName", wsData.getOrDefault("title", ""),
                    "createdDate", wsData.getOrDefault("createdAt", ""),
                    "lastActive", wsData.getOrDefault("lastOpened", ""),
                    "completionPercent", wsData.getOrDefault("progressPercent", 0.0),
                    "estimatedFinishDays", 14
            ));
            responseMap.put("roadmapNodes", wsData.getOrDefault("roadmap", List.of()));
            responseMap.put("attentionItems", List.of());
        }
        
        return ResponseEntity.ok(responseMap);
    }

    private List<Integer> generateHeatmap() {
        Integer[] scores = new Integer[365];
        for (int i = 0; i < 365; i++) {
            scores[i] = 0;
        }
        return List.of(scores);
    }
}
