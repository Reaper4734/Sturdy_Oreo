import 'dart:math';

// Dashboard Redesign v2.1 Data Models
class DashboardMockProfile {
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
  
  const DashboardMockProfile({
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

class MockDashboardRepository {
  static final _random = Random();

  Future<DashboardMockProfile> fetchDashboardProfile() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    return _profiles[_random.nextInt(_profiles.length)];
  }

  static String getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static HeatmapSummary computeHeatmapSummary(List<int> scores) {
    int sessions = scores.where((s) => s > 0).length;
    double hours = scores.fold<double>(0, (sum, s) => sum + (s / 100) * 3.5);
    int longest = 0, current = 0;
    for (final s in scores) {
      if (s > 0) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    
    // Calculate weekly consistency
    int consistentWeeks = 0;
    for (int i = 0; i < 52; i++) {
      int weekSessions = 0;
      for (int j = 0; j < 7; j++) {
        int index = i * 7 + j;
        if (index < scores.length && scores[index] > 0) {
          weekSessions++;
        }
      }
      if (weekSessions >= 3) consistentWeeks++;
    }
    int weeklyConsistency = ((consistentWeeks / 52) * 100).round();

    return HeatmapSummary(
      totalSessions: sessions,
      totalHours: double.parse(hours.toStringAsFixed(0)),
      longestStreak: longest,
      weeklyConsistency: weeklyConsistency,
    );
  }

  static List<int> _generateHeatmap(int activeDays, int avgScore) {
    final r = Random(42);
    return List.generate(365, (i) {
      if (r.nextInt(365) < activeDays) {
        return (avgScore + r.nextInt(30) - 15).clamp(5, 100);
      }
      return 0;
    });
  }

  static final List<DashboardMockProfile> _profiles = [
    // 1. Beginner
    DashboardMockProfile(
      learnerName: 'Priyaj',
      greetingInsight: 'You mastered Async Programming yesterday. Only Database Architecture and the Final Assessment remain.',
      recommendation: 'Today\'s session could complete your backend journey.',
      continueLearning: const ContinueLearningData(
        workspaceName: 'Python Backend Engineering',
        currentCourse: 'Python Fundamentals',
        difficulty: 'Beginner',
        currentTopic: 'Functions & Scope',
        nextAction: 'Complete Quiz 3',
        estimatedTime: '18 minutes',
        progressPercent: 0.12,
      ),
      journey: const LearningJourneyData(
        overallProgress: 0.12,
        level: 2,
        xp: 180,
        streakDays: 3,
        hoursLearned: 8,
        hoursRemaining: 86,
      ),
      roadmapNodes: const [
        RoadmapPreviewNode(title: 'Variables', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'Control Flow', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'Functions', status: RoadmapNodeStatus.active),
        RoadmapPreviewNode(title: 'Data Structures', status: RoadmapNodeStatus.locked),
        RoadmapPreviewNode(title: 'OOP Basics', status: RoadmapNodeStatus.locked),
        RoadmapPreviewNode(title: 'File I/O', status: RoadmapNodeStatus.locked),
        RoadmapPreviewNode(title: 'Error Handling', status: RoadmapNodeStatus.locked),
      ],
      attentionItems: const [
        AttentionItem(title: 'Complete Intro Quiz', subtitle: 'Variables & Data Types', type: AttentionType.pendingQuiz),
      ],
      timelineEvents: const [
        TimelineEvent(title: 'Completed Topic: Control Flow', relativeTime: '2 hours ago', optionalXp: 50),
        TimelineEvent(title: 'Completed Topic: Variables', relativeTime: 'Yesterday', optionalXp: 20),
        TimelineEvent(title: 'Generated Learning Roadmap', relativeTime: 'Yesterday'),
        TimelineEvent(title: 'Created Workspace', relativeTime: '3 days ago'),
      ],
      workspaceSummary: const WorkspaceSummaryData(
        workspaceName: 'Python Backend Engineering',
        createdDate: '3 days ago',
        lastActive: 'Today',
        completionPercent: 0.12,
        estimatedFinishDays: 14,
      ),
      heatmapScores: _generateHeatmap(8, 40),
    ),
    // 2. Intermediate
    DashboardMockProfile(
      learnerName: 'Priyaj',
      greetingInsight: 'Over your last three sessions you completed Python OOP fundamentals and strengthened your understanding of inheritance.',
      recommendation: 'Today your roadmap naturally continues with polymorphism.',
      continueLearning: const ContinueLearningData(
        workspaceName: 'Python Backend Engineering',
        currentCourse: 'Object-Oriented Programming',
        difficulty: 'Intermediate',
        currentTopic: 'Polymorphism',
        nextAction: 'Build Base Classes',
        estimatedTime: '45 minutes',
        progressPercent: 0.63,
      ),
      journey: const LearningJourneyData(
        overallProgress: 0.63,
        level: 8,
        xp: 1240,
        streakDays: 18,
        hoursLearned: 72,
        hoursRemaining: 34,
      ),
      roadmapNodes: const [
        RoadmapPreviewNode(title: 'Basics', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'Functions', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'OOP', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'Inheritance', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'Polymorphism', status: RoadmapNodeStatus.active),
        RoadmapPreviewNode(title: 'Memory Management', status: RoadmapNodeStatus.locked),
        RoadmapPreviewNode(title: 'Projects', status: RoadmapNodeStatus.locked),
      ],
      attentionItems: const [
        AttentionItem(title: 'Pending Quiz', subtitle: 'Inheritance Concepts', type: AttentionType.pendingQuiz),
        AttentionItem(title: 'Resume Project', subtitle: 'Class Hierarchy Builder', type: AttentionType.resumeProject),
      ],
      timelineEvents: const [
        TimelineEvent(title: 'Completed Quiz: OOP Basics', relativeTime: '2 hours ago', optionalXp: 120),
        TimelineEvent(title: 'Finished Topic: Inheritance', relativeTime: '5 hours ago', optionalXp: 80),
        TimelineEvent(title: 'Completed Project: Data Modeling', relativeTime: 'Yesterday', optionalXp: 300),
        TimelineEvent(title: 'Finished Topic: Encapsulation', relativeTime: 'Yesterday', optionalXp: 100),
      ],
      workspaceSummary: const WorkspaceSummaryData(
        workspaceName: 'Python Backend Engineering',
        createdDate: '2 weeks ago',
        lastActive: 'Today',
        completionPercent: 0.63,
        estimatedFinishDays: 8,
      ),
      heatmapScores: _generateHeatmap(120, 65),
    ),
    // 3. Advanced
    DashboardMockProfile(
      learnerName: 'Priyaj',
      greetingInsight: 'You\'ve mastered 89% of your Python Backend Engineering path. Your concurrency and async modules are complete.',
      recommendation: 'Only the capstone project and final assessment remain.',
      continueLearning: const ContinueLearningData(
        workspaceName: 'Python Backend Engineering',
        currentCourse: 'Advanced Architecture',
        difficulty: 'Advanced',
        currentTopic: 'Capstone Project',
        nextAction: 'Define WebSocket Interfaces',
        estimatedTime: '2 hours',
        progressPercent: 0.89,
      ),
      journey: const LearningJourneyData(
        overallProgress: 0.89,
        level: 14,
        xp: 3420,
        streakDays: 45,
        hoursLearned: 156,
        hoursRemaining: 12,
      ),
      roadmapNodes: const [
        RoadmapPreviewNode(title: 'Basics', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'OOP', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'Memory', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'Async', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'Concurrency', status: RoadmapNodeStatus.completed),
        RoadmapPreviewNode(title: 'Capstone Project', status: RoadmapNodeStatus.active),
        RoadmapPreviewNode(title: 'Assessment', status: RoadmapNodeStatus.locked),
      ],
      attentionItems: const [],
      timelineEvents: const [
        TimelineEvent(title: 'Completed Topic: WebSocket Protocol', relativeTime: '1 hour ago', optionalXp: 150),
        TimelineEvent(title: 'Perfect Quiz: Async Patterns', relativeTime: '3 hours ago', optionalXp: 200),
        TimelineEvent(title: 'Completed Project: Async Server', relativeTime: 'Yesterday', optionalXp: 500),
      ],
      workspaceSummary: const WorkspaceSummaryData(
        workspaceName: 'Python Backend Engineering',
        createdDate: '1 month ago',
        lastActive: 'Today',
        completionPercent: 0.89,
        estimatedFinishDays: 3,
      ),
      heatmapScores: _generateHeatmap(280, 78),
    ),
  ];
}
