package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.schemas.DashboardProfileSchema;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    @GetMapping("/profile")
    public ResponseEntity<DashboardProfileSchema> getDashboardProfile() {
        DashboardProfileSchema profile = new DashboardProfileSchema();
        
        profile.setLearnerName("Priyaj (Live API)");
        profile.setGreetingInsight("Welcome back! The backend is now fully powering your Dashboard via Spring Boot APIs.");
        profile.setRecommendation("You're doing great! Keep building Oreo AI.");

        DashboardProfileSchema.ContinueLearningData continueLearning = new DashboardProfileSchema.ContinueLearningData();
        continueLearning.setWorkspaceName("Agentic AI Development");
        continueLearning.setCurrentCourse("Building AI Workspaces");
        continueLearning.setDifficulty("Advanced");
        continueLearning.setCurrentTopic("Dynamic Dashboards");
        continueLearning.setNextAction("Complete Phase 5 API Integration");
        continueLearning.setEstimatedTime("15 minutes");
        continueLearning.setProgressPercent(0.85);
        profile.setContinueLearning(continueLearning);

        DashboardProfileSchema.LearningJourneyData journey = new DashboardProfileSchema.LearningJourneyData();
        journey.setOverallProgress(0.85);
        journey.setLevel(5);
        journey.setXp(1450);
        journey.setStreakDays(7);
        journey.setHoursLearned(120.5);
        journey.setHoursRemaining(24.0);
        profile.setJourney(journey);

        List<DashboardProfileSchema.RoadmapPreviewNode> nodes = new ArrayList<>();
        DashboardProfileSchema.RoadmapPreviewNode n1 = new DashboardProfileSchema.RoadmapPreviewNode();
        n1.setTitle("Authentication"); n1.setStatus("completed");
        DashboardProfileSchema.RoadmapPreviewNode n2 = new DashboardProfileSchema.RoadmapPreviewNode();
        n2.setTitle("Workspaces"); n2.setStatus("completed");
        DashboardProfileSchema.RoadmapPreviewNode n3 = new DashboardProfileSchema.RoadmapPreviewNode();
        n3.setTitle("Dashboard APIs"); n3.setStatus("active");
        DashboardProfileSchema.RoadmapPreviewNode n4 = new DashboardProfileSchema.RoadmapPreviewNode();
        n4.setTitle("Flashcards"); n4.setStatus("locked");
        nodes.add(n1); nodes.add(n2); nodes.add(n3); nodes.add(n4);
        profile.setRoadmapNodes(nodes);

        List<DashboardProfileSchema.AttentionItem> attentionItems = new ArrayList<>();
        DashboardProfileSchema.AttentionItem a1 = new DashboardProfileSchema.AttentionItem();
        a1.setTitle("Complete Phase 5");
        a1.setSubtitle("API Integration");
        a1.setType("resumeProject");
        attentionItems.add(a1);
        profile.setAttentionItems(attentionItems);

        List<DashboardProfileSchema.TimelineEvent> events = new ArrayList<>();
        DashboardProfileSchema.TimelineEvent e1 = new DashboardProfileSchema.TimelineEvent();
        e1.setTitle("Connected Dashboard to Spring Boot API");
        e1.setRelativeTime("Just now");
        e1.setOptionalXp(200);
        events.add(e1);
        profile.setTimelineEvents(events);

        DashboardProfileSchema.WorkspaceSummaryData summary = new DashboardProfileSchema.WorkspaceSummaryData();
        summary.setWorkspaceName("Agentic AI Development");
        summary.setCreatedDate("1 week ago");
        summary.setLastActive("Today");
        summary.setCompletionPercent(0.85);
        summary.setEstimatedFinishDays(3);
        profile.setWorkspaceSummary(summary);

        List<Integer> heatmap = new ArrayList<>();
        Random random = new Random();
        for (int i = 0; i < 365; i++) {
            heatmap.add(i % 3 == 0 ? random.nextInt(100) : 0);
        }
        profile.setHeatmapScores(heatmap);

        return ResponseEntity.ok(profile);
    }
}
