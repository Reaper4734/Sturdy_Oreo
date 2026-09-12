package com.oreo.engine.orchestration.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.oreo.auth.User;
import com.oreo.auth.UserRepository;
import com.oreo.engine.orchestration.model.Workspace;
import com.oreo.engine.orchestration.repository.FlashcardRepository;
import com.oreo.engine.orchestration.repository.WorkspaceRepository;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final UserRepository userRepository;
    private final WorkspaceRepository workspaceRepository;
    private final FlashcardRepository flashcardRepository;

    public DashboardController(UserRepository userRepository, 
                               WorkspaceRepository workspaceRepository,
                               FlashcardRepository flashcardRepository) {
        this.userRepository = userRepository;
        this.workspaceRepository = workspaceRepository;
        this.flashcardRepository = flashcardRepository;
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
        String learnerName = user.getDisplayName() != null && !user.getDisplayName().isBlank() ? user.getDisplayName() : "Learner";
        int streak = user.getCurrentStreak();
        int xp = user.getTotalPoints();
        int level = Math.max(1, xp / 100);

        List<Workspace> workspaces = workspaceRepository.findByUserId(userId);

        // Calculate real aggregate learning progress and hours from user's workspaces
        double totalProgressSum = 0.0;
        int totalTopicsCount = 0;
        int completedTopicsCount = 0;

        double totalHoursSum = 0.0;
        double completedHoursSum = 0.0;

        for (Workspace ws : workspaces) {
            Map<String, Object> data = ws.getData() != null ? ws.getData() : Map.of();
            double wsProgress = getDoubleValue(data.get("progressPercent"), 0.0);
            totalProgressSum += wsProgress;

            Object roadmapObj = data.get("roadmap");
            if (roadmapObj instanceof List<?>) {
                List<?> roadmap = (List<?>) roadmapObj;
                totalTopicsCount += roadmap.size();
                completedTopicsCount += (int) Math.round(roadmap.size() * wsProgress);

                double wsTotalHours = 0.0;
                for (Object item : roadmap) {
                    if (item instanceof Map<?, ?> node) {
                        wsTotalHours += getDoubleValue(node.get("estimatedHours"), 2.0);
                    } else {
                        wsTotalHours += 2.0;
                    }
                }
                totalHoursSum += wsTotalHours;
                completedHoursSum += (wsTotalHours * wsProgress);
            }
        }

        double overallProgress = workspaces.isEmpty() ? 0.0 : (totalProgressSum / workspaces.size());
        double hoursLearned = Math.round(completedHoursSum * 10.0) / 10.0;
        double hoursRemaining = Math.max(0.0, Math.round((totalHoursSum - completedHoursSum) * 10.0) / 10.0);

        // Construct dynamic timeline events based on actual workspace history
        List<Map<String, Object>> timelineEvents = new ArrayList<>();
        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("MMM dd");
        for (Workspace ws : workspaces) {
            if (ws.getCreatedAt() != null) {
                timelineEvents.add(Map.of(
                        "title", "Started curriculum: " + ws.getTitle(),
                        "relativeTime", ws.getCreatedAt().format(dtf),
                        "optionalXp", "+50 XP"
                ));
            }
        }

        // Construct dynamic attention items based on flashcard review schedule & unfinished workspaces
        List<Map<String, Object>> attentionItems = new ArrayList<>();
        var dueCards = flashcardRepository.findByUserIdAndNextReviewDateLessThanEqual(userId, LocalDate.now());
        if (!dueCards.isEmpty()) {
            attentionItems.add(Map.of(
                    "title", "Flashcard Review Due",
                    "subtitle", dueCards.size() + " concept flashcards scheduled for review today",
                    "type", "reviewSuggested"
            ));
        }

        java.util.Map<String, Object> responseMap = new java.util.HashMap<>();
        responseMap.put("learnerName", learnerName);
        responseMap.put("greetingInsight", streak > 1 
                ? "You're on a " + streak + "-day learning streak! Keep your momentum going."
                : "Welcome to your command center. Select a module to begin learning.");
        responseMap.put("recommendation", workspaces.isEmpty() 
                ? "Explore the catalog to create your first learning workspace."
                : "Continue progressing on your active workspace modules.");
        responseMap.put("journey", Map.of(
                "overallProgress", overallProgress,
                "level", level,
                "xp", xp,
                "streakDays", streak,
                "hoursLearned", hoursLearned,
                "hoursRemaining", hoursRemaining
        ));
        responseMap.put("timelineEvents", timelineEvents);
        responseMap.put("heatmapScores", generateDynamicHeatmap(user, workspaces));
        
        if (!workspaces.isEmpty()) {
            Workspace selected = null;
            if (workspaceId != null && !workspaceId.isEmpty()) {
                selected = workspaces.stream().filter(w -> w.getId().equals(workspaceId)).findFirst().orElse(null);
            }
            if (selected == null) {
                selected = workspaces.stream().max(Comparator.comparing(w -> {
                    String lastOpened = (String) w.getData().getOrDefault("lastOpened", "");
                    return lastOpened.isEmpty() ? w.getCreatedAt().toString() : lastOpened;
                })).orElse(workspaces.get(0));
            }

            Map<String, Object> wsData = selected.getData() != null ? selected.getData() : Map.of();
            String activeContext = (String) wsData.getOrDefault("activeLearningContext", selected.getTitle());
            double progress = getDoubleValue(wsData.get("progressPercent"), 0.0);
            int estimatedDaysLeft = Math.max(1, (int) Math.ceil((1.0 - progress) * 14));

            responseMap.put("continueLearning", Map.of(
                    "workspaceName", wsData.getOrDefault("title", selected.getTitle()),
                    "currentCourse", activeContext,
                    "difficulty", wsData.getOrDefault("difficulty", "Intermediate"),
                    "currentTopic", activeContext,
                    "nextAction", progress >= 1.0 ? "Review Mastery" : "Continue Next Lesson",
                    "estimatedTime", "45m",
                    "progressPercent", progress
            ));
            responseMap.put("workspaceSummary", Map.of(
                    "workspaceName", wsData.getOrDefault("title", selected.getTitle()),
                    "createdDate", selected.getCreatedAt() != null ? selected.getCreatedAt().format(dtf) : "Recent",
                    "lastActive", wsData.getOrDefault("lastOpened", "Today"),
                    "completionPercent", progress,
                    "estimatedFinishDays", estimatedDaysLeft
            ));
            responseMap.put("roadmapNodes", wsData.getOrDefault("roadmap", List.of()));

            if (progress < 1.0 && attentionItems.isEmpty()) {
                attentionItems.add(Map.of(
                        "title", "Next Focus: " + activeContext,
                        "subtitle", "Complete the upcoming module to progress on " + selected.getTitle(),
                        "type", "resumeProject"
                ));
            }
        }

        responseMap.put("attentionItems", attentionItems);
        return ResponseEntity.ok(responseMap);
    }

    private List<Integer> generateDynamicHeatmap(User user, List<Workspace> workspaces) {
        Integer[] scores = new Integer[365];
        Arrays.fill(scores, 0);

        // Record activity on user's last active date
        if (user.getLastActiveDate() != null) {
            int activeDay = user.getLastActiveDate().getDayOfYear() - 1;
            if (activeDay >= 0 && activeDay < 365) {
                scores[activeDay] = Math.min(100, Math.max(20, user.getTotalPoints()));
            }
        }

        // Record activity from actual workspace creations and modifications
        for (Workspace ws : workspaces) {
            if (ws.getCreatedAt() != null) {
                int wsDay = ws.getCreatedAt().getDayOfYear() - 1;
                if (wsDay >= 0 && wsDay < 365) {
                    scores[wsDay] = 100;
                }
            }
        }

        return List.of(scores);
    }

    private double getDoubleValue(Object val, double fallback) {
        if (val instanceof Number) {
            return ((Number) val).doubleValue();
        }
        return fallback;
    }
}
