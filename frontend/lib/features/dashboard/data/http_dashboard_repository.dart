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
        
        final List<int> heatmap = (data['heatmapScores'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ?? List.filled(365, 0);

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
          heatmapScores: heatmap,
        );
      }
    } catch (_) {
      // Fallback safe default profile so caller never crashes or hangs
    }

    return DashboardProfile(
      learnerName: 'Scholar',
      greetingInsight: 'Welcome to your command center. Select a module to begin learning.',
      recommendation: 'Continue progressing on your active workspace modules.',
      continueLearning: _parseContinueLearning(null),
      journey: _parseJourney(null),
      roadmapNodes: const [],
      attentionItems: const [],
      timelineEvents: const [],
      workspaceSummary: _parseWorkspaceSummary(null),
      heatmapScores: List.filled(365, 0),
    );
  }

  ContinueLearningData _parseContinueLearning(dynamic data) {
    if (data == null || data is! Map) {
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
      workspaceName: data['workspaceName']?.toString() ?? '',
      currentCourse: data['currentCourse']?.toString() ?? '',
      difficulty: data['difficulty']?.toString() ?? '',
      currentTopic: data['currentTopic']?.toString() ?? '',
      nextAction: data['nextAction']?.toString() ?? '',
      estimatedTime: data['estimatedTime']?.toString() ?? '',
      progressPercent: ((data['progressPercent'] as num?) ?? 0).toDouble(),
    );
  }

  LearningJourneyData _parseJourney(dynamic data) {
    if (data == null || data is! Map) {
      return const LearningJourneyData(
        overallProgress: 0.0,
        level: 1,
        xp: 0,
        streakDays: 1,
        hoursLearned: 0.0,
        hoursRemaining: 10.0,
      );
    }
    return LearningJourneyData(
      overallProgress: ((data['overallProgress'] as num?) ?? 0).toDouble(),
      level: ((data['level'] as num?) ?? 1).toInt(),
      xp: ((data['xp'] as num?) ?? 0).toInt(),
      streakDays: ((data['streakDays'] as num?) ?? 0).toInt(),
      hoursLearned: ((data['hoursLearned'] as num?) ?? 0).toDouble(),
      hoursRemaining: ((data['hoursRemaining'] as num?) ?? 0).toDouble(),
    );
  }

  List<RoadmapPreviewNode> _parseRoadmapNodes(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map((n) {
      if (n is! Map) return const RoadmapPreviewNode(title: '', status: RoadmapNodeStatus.locked);
      final statusStr = n['status']?.toString().toLowerCase() ?? 'locked';
      RoadmapNodeStatus status = RoadmapNodeStatus.locked;
      if (statusStr == 'completed') status = RoadmapNodeStatus.completed;
      if (statusStr == 'active') status = RoadmapNodeStatus.active;
      
      return RoadmapPreviewNode(
        title: n['title']?.toString() ?? '',
        status: status,
      );
    }).toList();
  }

  List<AttentionItem> _parseAttentionItems(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map((a) {
      if (a is! Map) return const AttentionItem(title: '', subtitle: '', type: AttentionType.resumeProject);
      final typeStr = a['type']?.toString() ?? 'resumeProject';
      AttentionType type = AttentionType.resumeProject;
      if (typeStr == 'pendingQuiz') type = AttentionType.pendingQuiz;
      if (typeStr == 'reviewSuggested') type = AttentionType.reviewSuggested;
      if (typeStr == 'remedialLesson') type = AttentionType.remedialLesson;

      return AttentionItem(
        title: a['title']?.toString() ?? '',
        subtitle: a['subtitle']?.toString() ?? '',
        type: type,
      );
    }).toList();
  }

  List<TimelineEvent> _parseTimelineEvents(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map((e) {
      if (e is! Map) return const TimelineEvent(title: '', relativeTime: '');
      int? xp;
      if (e['optionalXp'] is num) {
        xp = (e['optionalXp'] as num).toInt();
      } else if (e['optionalXp'] != null) {
        xp = int.tryParse(e['optionalXp'].toString().replaceAll(RegExp(r'[^\d]'), ''));
      }
      return TimelineEvent(
        title: e['title']?.toString() ?? '',
        relativeTime: e['relativeTime']?.toString() ?? '',
        optionalXp: xp,
      );
    }).toList();
  }

  WorkspaceSummaryData _parseWorkspaceSummary(dynamic data) {
    if (data == null || data is! Map) {
      return const WorkspaceSummaryData(
        workspaceName: '',
        createdDate: '',
        lastActive: '',
        completionPercent: 0.0,
        estimatedFinishDays: 0,
      );
    }
    return WorkspaceSummaryData(
      workspaceName: data['workspaceName']?.toString() ?? '',
      createdDate: data['createdDate']?.toString() ?? '',
      lastActive: data['lastActive']?.toString() ?? '',
      completionPercent: ((data['completionPercent'] as num?) ?? 0).toDouble(),
      estimatedFinishDays: ((data['estimatedFinishDays'] as num?) ?? 0).toInt(),
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
