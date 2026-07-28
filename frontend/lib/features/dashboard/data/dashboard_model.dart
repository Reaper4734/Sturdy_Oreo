// Dashboard Redesign v2.1 Data Models
class DashboardProfile {
  final String learnerName;
  final String greetingInsight;
  final String recommendation;
  final ContinueLearningData continueLearning;
  final LearningJourneyData journey;
  final List<RoadmapPreviewNode> roadmapNodes;
  final List<AttentionItem> attentionItems;
  final List<TimelineEvent> timelineEvents;
  final WorkspaceSummaryData workspaceSummary;
  final List<int> heatmapScores; // 365 days of learning scores (0-100)
  
  const DashboardProfile({
    required this.learnerName,
    required this.greetingInsight,
    required this.recommendation,
    required this.continueLearning,
    required this.journey,
    required this.roadmapNodes,
    required this.attentionItems,
    required this.timelineEvents,
    required this.workspaceSummary,
    required this.heatmapScores,
  });
}

class ContinueLearningData {
  final String workspaceName;
  final String currentCourse;
  final String difficulty;
  final String currentTopic;
  final String nextAction;
  final String estimatedTime;
  final double progressPercent; // 0.0 to 1.0

  const ContinueLearningData({
    required this.workspaceName,
    required this.currentCourse,
    required this.difficulty,
    required this.currentTopic,
    required this.nextAction,
    required this.estimatedTime,
    required this.progressPercent,
  });
}

class LearningJourneyData {
  final double overallProgress; // 0.0 to 1.0
  final int level;
  final int xp;
  final int streakDays;
  final double hoursLearned;
  final double hoursRemaining;

  const LearningJourneyData({
    required this.overallProgress,
    required this.level,
    required this.xp,
    required this.streakDays,
    required this.hoursLearned,
    required this.hoursRemaining,
  });
}

enum RoadmapNodeStatus { completed, active, locked }

class RoadmapPreviewNode {
  final String title;
  final RoadmapNodeStatus status;

  const RoadmapPreviewNode({required this.title, required this.status});
}

enum AttentionType { pendingQuiz, resumeProject, reviewSuggested, remedialLesson }

class AttentionItem {
  final String title;
  final String subtitle;
  final AttentionType type;

  const AttentionItem({
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

class TimelineEvent {
  final String title;
  final String relativeTime;
  final int? optionalXp;

  const TimelineEvent({required this.title, required this.relativeTime, this.optionalXp});
}

class WorkspaceSummaryData {
  final String workspaceName;
  final String createdDate;
  final String lastActive;
  final double completionPercent;
  final int estimatedFinishDays;

  const WorkspaceSummaryData({
    required this.workspaceName,
    required this.createdDate,
    required this.lastActive,
    required this.completionPercent,
    required this.estimatedFinishDays,
  });
}

class HeatmapSummary {
  final int totalSessions;
  final double totalHours;
  final int longestStreak;
  final int weeklyConsistency;

  const HeatmapSummary({
    required this.totalSessions,
    required this.totalHours,
    required this.longestStreak,
    required this.weeklyConsistency,
  });
}


