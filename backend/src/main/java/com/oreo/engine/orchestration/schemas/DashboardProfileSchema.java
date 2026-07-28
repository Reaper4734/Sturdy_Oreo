package com.oreo.engine.orchestration.schemas;

import lombok.Data;
import java.util.List;

@Data
public class DashboardProfileSchema {
    private String learnerName;
    private String greetingInsight;
    private String recommendation;
    private ContinueLearningData continueLearning;
    private LearningJourneyData journey;
    private List<RoadmapPreviewNode> roadmapNodes;
    private List<AttentionItem> attentionItems;
    private List<TimelineEvent> timelineEvents;
    private WorkspaceSummaryData workspaceSummary;
    private List<Integer> heatmapScores;

    @Data
    public static class ContinueLearningData {
        private String workspaceName;
        private String currentCourse;
        private String difficulty;
        private String currentTopic;
        private String nextAction;
        private String estimatedTime;
        private double progressPercent;
    }

    @Data
    public static class LearningJourneyData {
        private double overallProgress;
        private int level;
        private int xp;
        private int streakDays;
        private double hoursLearned;
        private double hoursRemaining;
    }

    @Data
    public static class RoadmapPreviewNode {
        private String title;
        private String status;
    }

    @Data
    public static class AttentionItem {
        private String title;
        private String subtitle;
        private String type;
    }

    @Data
    public static class TimelineEvent {
        private String title;
        private String relativeTime;
        private Integer optionalXp;
    }

    @Data
    public static class WorkspaceSummaryData {
        private String workspaceName;
        private String createdDate;
        private String lastActive;
        private double completionPercent;
        private int estimatedFinishDays;
    }
}
