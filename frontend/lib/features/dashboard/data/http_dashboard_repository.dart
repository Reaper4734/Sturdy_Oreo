import 'dart:convert';
import 'package:frontend/core/api_client.dart';
import 'dashboard_model.dart';

class HttpDashboardRepository {
  final ApiClient _apiClient = ApiClient();

  Future<DashboardProfile> fetchDashboardProfile({String? workspaceId}) async {
    try {
      final path = workspaceId != null && workspaceId.isNotEmpty
          ? '/dashboard/profile?workspaceId=$workspaceId'
          : '/dashboard/profile';
      final response = await _apiClient.get(path);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return DashboardProfile(
          learnerName: data['learnerName'] ?? 'Learner',
          greetingInsight: data['greetingInsight'] ?? 'Welcome back!',
          recommendation: data['recommendation'] ?? 'Keep learning!',
          continueLearning: _parseContinueLearning(data['continueLearning']),
          journey: _parseJourney(data['journey']),
          roadmapNodes: _parseRoadmapNodes(data['roadmapNodes']),
          attentionItems: _parseAttentionItems(data['attentionItems']),
          timelineEvents: _parseTimelineEvents(data['timelineEvents']),
          workspaceSummary: _parseWorkspaceSummary(data['workspaceSummary']),
          heatmapScores: List<int>.from(data['heatmapScores'] ?? List.filled(365, 0)),
        );
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  ContinueLearningData _parseContinueLearning(Map<String, dynamic>? data) {
    if (data == null) {
      return const ContinueLearningData(
        workspaceName: 'No active workspace',
        currentCourse: '',
        difficulty: '',
        currentTopic: '',
        nextAction: 'Start a new journey',
        estimatedTime: '',
        progressPercent: 0.0,
      );
    }
    return ContinueLearningData(
      workspaceName: data['workspaceName'] ?? '',
      currentCourse: data['currentCourse'] ?? '',
      difficulty: data['difficulty'] ?? '',
      currentTopic: data['currentTopic'] ?? '',
      nextAction: data['nextAction'] ?? '',
      estimatedTime: data['estimatedTime'] ?? '',
      progressPercent: (data['progressPercent'] ?? 0).toDouble(),
    );
  }

  LearningJourneyData _parseJourney(Map<String, dynamic>? data) {
    if (data == null) throw Exception('journey missing');
    return LearningJourneyData(
      overallProgress: (data['overallProgress'] ?? 0).toDouble(),
      level: data['level'] ?? 1,
      xp: data['xp'] ?? 0,
      streakDays: data['streakDays'] ?? 0,
      hoursLearned: (data['hoursLearned'] ?? 0).toDouble(),
      hoursRemaining: (data['hoursRemaining'] ?? 0).toDouble(),
    );
  }

  List<RoadmapPreviewNode> _parseRoadmapNodes(List<dynamic>? data) {
    if (data == null) return [];
    return data.map((n) {
      final statusStr = n['status'] as String? ?? 'locked';
      RoadmapNodeStatus status = RoadmapNodeStatus.locked;
      if (statusStr == 'completed') status = RoadmapNodeStatus.completed;
      if (statusStr == 'active') status = RoadmapNodeStatus.active;
      
      return RoadmapPreviewNode(
        title: n['title'] ?? '',
        status: status,
      );
    }).toList();
  }

  List<AttentionItem> _parseAttentionItems(List<dynamic>? data) {
    if (data == null) return [];
    return data.map((a) {
      final typeStr = a['type'] as String? ?? 'resumeProject';
      AttentionType type = AttentionType.resumeProject;
      if (typeStr == 'pendingQuiz') type = AttentionType.pendingQuiz;
      if (typeStr == 'reviewSuggested') type = AttentionType.reviewSuggested;
      if (typeStr == 'remedialLesson') type = AttentionType.remedialLesson;

      return AttentionItem(
        title: a['title'] ?? '',
        subtitle: a['subtitle'] ?? '',
        type: type,
      );
    }).toList();
  }

  List<TimelineEvent> _parseTimelineEvents(List<dynamic>? data) {
    if (data == null) return [];
    return data.map((e) => TimelineEvent(
      title: e['title'] ?? '',
      relativeTime: e['relativeTime'] ?? '',
      optionalXp: e['optionalXp'],
    )).toList();
  }

  WorkspaceSummaryData _parseWorkspaceSummary(Map<String, dynamic>? data) {
    if (data == null) {
      return const WorkspaceSummaryData(
        workspaceName: '',
        createdDate: '',
        lastActive: '',
        completionPercent: 0.0,
        estimatedFinishDays: 0,
      );
    }
    return WorkspaceSummaryData(
      workspaceName: data['workspaceName'] ?? '',
      createdDate: data['createdDate'] ?? '',
      lastActive: data['lastActive'] ?? '',
      completionPercent: (data['completionPercent'] ?? 0).toDouble(),
      estimatedFinishDays: data['estimatedFinishDays'] ?? 0,
    );
  }

  static String getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static HeatmapSummary computeHeatmapSummary(List<int> scores) {
    int totalSessions = 0;
    double totalHours = 0;
    int currentStreak = 0;
    int longestStreak = 0;
    
    for (int score in scores) {
      if (score > 0) {
        totalSessions++;
        totalHours += (score / 100.0) * 2; // rough approx
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }
    
    return HeatmapSummary(
      totalSessions: totalSessions,
      totalHours: totalHours,
      longestStreak: longestStreak,
      weeklyConsistency: totalSessions > 0 ? ((totalSessions / (scores.length / 7)) * 100).clamp(0, 100).toInt() : 0,
    );
  }
}
