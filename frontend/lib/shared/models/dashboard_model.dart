enum NodeStatus { locked, active, mastered }

class DashboardSkillNode {
  final String id;
  final String title;
  final String description;
  final NodeStatus status;
  final List<String> prerequisiteIds;
  final String category;
  final int estimatedMinutes;

  const DashboardSkillNode({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.prerequisiteIds,
    this.category = 'Core Concept',
    this.estimatedMinutes = 15,
  });
}

class DashboardFlashcard {
  final String id;
  final String front;
  final String back;
  final DateTime nextReviewDate;
  final int intervalDays;
  final double easeFactor;
  final int consecutiveCorrectAnswers;
  final String topic;

  const DashboardFlashcard({
    required this.id,
    required this.front,
    required this.back,
    required this.nextReviewDate,
    this.intervalDays = 1,
    this.easeFactor = 2.5,
    this.consecutiveCorrectAnswers = 0,
    required this.topic,
  });
}

class DashboardTrack {
  final String id;
  final String goal;
  final String status;
  final List<DashboardSkillNode> nodes;

  const DashboardTrack({
    required this.id,
    required this.goal,
    required this.status,
    required this.nodes,
  });
}

class DashboardStats {
  final int totalNodes;
  final int masteredNodes;
  final int activeNodes;
  final int dueCardsToday;
  final int streakDays;

  const DashboardStats({
    required this.totalNodes,
    required this.masteredNodes,
    required this.activeNodes,
    required this.dueCardsToday,
    required this.streakDays,
  });

  double get masteryPercentage =>
      totalNodes == 0 ? 0.0 : (masteredNodes / totalNodes) * 100;
}

enum ActivityType { nodeMastered, cardReviewed, watchdogNudge, quizPassed }

class ActivityEntry {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  const ActivityEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}
