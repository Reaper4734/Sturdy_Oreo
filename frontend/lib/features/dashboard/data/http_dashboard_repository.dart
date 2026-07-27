import 'dart:convert';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/features/dashboard/data/mock_dashboard_data.dart';

class HttpDashboardRepository {
  final ApiClient _apiClient = ApiClient();

  Future<DashboardMockProfile> fetchDashboardProfile() async {
    try {
      final response = await _apiClient.get('/dashboard/profile');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return DashboardMockProfile(
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
      }
    } catch (e) {
      print('Ponytail Backend Integration: /dashboard/profile failed ($e). Falling back to mock.');
    }
    
    return _fallbackProfile;
  }

  ContinueLearningData _parseContinueLearning(Map<String, dynamic>? data) {
    if (data == null) return _fallbackProfile.continueLearning;
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
    if (data == null) return _fallbackProfile.journey;
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
    if (data == null) return _fallbackProfile.roadmapNodes;
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
    if (data == null) return _fallbackProfile.attentionItems;
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
    if (data == null) return _fallbackProfile.timelineEvents;
    return data.map((e) => TimelineEvent(
      title: e['title'] ?? '',
      relativeTime: e['relativeTime'] ?? '',
      optionalXp: e['optionalXp'],
    )).toList();
  }

  WorkspaceSummaryData _parseWorkspaceSummary(Map<String, dynamic>? data) {
    if (data == null) return _fallbackProfile.workspaceSummary;
    return WorkspaceSummaryData(
      workspaceName: data['workspaceName'] ?? '',
      createdDate: data['createdDate'] ?? '',
      lastActive: data['lastActive'] ?? '',
      completionPercent: (data['completionPercent'] ?? 0).toDouble(),
      estimatedFinishDays: data['estimatedFinishDays'] ?? 0,
    );
  }

  static final DashboardMockProfile _fallbackProfile = DashboardMockProfile(
    learnerName: 'Priyaj',
    greetingInsight: 'Backend integration initialized! The UI is now powered by HttpDashboardRepository.',
    recommendation: 'Connect the Spring Boot endpoints to see live data.',
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
    ],
    attentionItems: const [
      AttentionItem(title: 'Complete Intro Quiz', subtitle: 'Variables & Data Types', type: AttentionType.pendingQuiz),
    ],
    timelineEvents: const [
      TimelineEvent(title: 'Swapped to HTTP Repository', relativeTime: 'Just now', optionalXp: 50),
    ],
    workspaceSummary: const WorkspaceSummaryData(
      workspaceName: 'Python Backend Engineering',
      createdDate: '3 days ago',
      lastActive: 'Today',
      completionPercent: 0.12,
      estimatedFinishDays: 14,
    ),
    heatmapScores: List.generate(365, (i) => i % 5 == 0 ? 40 : 0),
  );
}
