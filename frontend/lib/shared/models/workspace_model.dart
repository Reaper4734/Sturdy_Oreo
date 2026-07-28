import 'package:flutter/material.dart';
import 'dashboard_model.dart';
import 'flashcard_model.dart';
import 'learning_lab_model.dart';
import 'micro_interview_model.dart';
import 'mind_map_model.dart';
import 'persona_model.dart';
import 'roadmap_model.dart';

/// Represents an independent, isolated Learning Workspace project.
/// Grouping all conversation, roadmap, canvas, flashcard, and lab data
/// under a single project ID without data leakage.
class WorkspaceModel {
  final String id;
  final String userId;
  String title;
  String subject;
  String difficulty;             // e.g., 'Beginner', 'Intermediate', 'Advanced'
  final DateTime createdAt;
  DateTime lastOpened;
  double progressPercent;        // 0.0 to 1.0
  String activeLearningContext;  // Single source of truth (e.g., 'Inheritance', 'State Hooks')
  int flashcardCount;
  int roadmapNodeCount;
  Color accentColor;
  bool isPinned;
  bool isArchived;
  bool isCourseConfirmed;

  // Backwards-compatibility getter/setter for transition
  String get currentTopic => activeLearningContext;
  set currentTopic(String val) => activeLearningContext = val;
  int get videoTimestampSeconds => lastVideoTimestampSeconds;
  set videoTimestampSeconds(int val) => lastVideoTimestampSeconds = val;

  // Owned data artifacts (isolated to this workspace)
  PersonaProfile? persona;
  SubjectCluster? subjectCluster;
  List<RoadmapNode> roadmap;
  List<RoadmapEdge> edges;
  List<FlashcardItem> flashcards;
  List<CanvasGridCell> canvasCells;
  List<CanvasObject> canvasObjects;
  List<DrawingPath> drawingPaths;
  List<ChatMessage> chatHistory;
  List<ActivityEntry> activityFeed;
  List<DashboardTrack> tracks;

  // Resumption UI & state restoration
  String activeTabId;            // e.g., 'roadmap', 'mind_map', 'persona', etc.
  Map<String, bool> expandedRoadmapNodes;
  int lastVideoTimestampSeconds;

  WorkspaceModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    required this.difficulty,
    required this.createdAt,
    required this.lastOpened,
    required this.progressPercent,
    required this.activeLearningContext,
    required this.flashcardCount,
    required this.roadmapNodeCount,
    required this.accentColor,
    this.isPinned = false,
    this.isArchived = false,
    this.isCourseConfirmed = false,
    this.persona,
    this.subjectCluster,
    List<RoadmapNode>? roadmap,
    List<RoadmapEdge>? edges,
    List<FlashcardItem>? flashcards,
    List<CanvasGridCell>? canvasCells,
    List<CanvasObject>? canvasObjects,
    List<DrawingPath>? drawingPaths,
    List<ChatMessage>? chatHistory,
    List<ActivityEntry>? activityFeed,
    List<DashboardTrack>? tracks,
    this.activeTabId = 'roadmap',
    Map<String, bool>? expandedRoadmapNodes,
    this.lastVideoTimestampSeconds = 0,
  })  : roadmap = roadmap ?? [],
        edges = edges ?? [],
        flashcards = flashcards ?? [],
        canvasCells = canvasCells ?? [],
        canvasObjects = canvasObjects ?? [],
        drawingPaths = drawingPaths ?? [],
        chatHistory = chatHistory ?? [],
        activityFeed = activityFeed ?? [],
        tracks = tracks ?? [],
        expandedRoadmapNodes = expandedRoadmapNodes ?? {};

  /// Create a cloned copy of this workspace (for Duplication action)
  WorkspaceModel clone({required String newId, required String newTitle}) {
    return WorkspaceModel(
      id: newId,
      userId: userId,
      title: newTitle,
      subject: subject,
      difficulty: difficulty,
      createdAt: DateTime.now(),
      lastOpened: DateTime.now(),
      progressPercent: progressPercent,
      activeLearningContext: activeLearningContext,
      flashcardCount: flashcardCount,
      roadmapNodeCount: roadmapNodeCount,
      accentColor: accentColor,
      isPinned: isPinned,
      isArchived: isArchived,
      isCourseConfirmed: isCourseConfirmed,
      persona: persona,
      subjectCluster: subjectCluster,
      roadmap: roadmap.map((r) => r.clone()).toList(),
      flashcards: List.from(flashcards),
      canvasCells: List.from(canvasCells),
      canvasObjects: List.from(canvasObjects),
      drawingPaths: List.from(drawingPaths),
      chatHistory: List.from(chatHistory),
      activityFeed: List.from(activityFeed),
      tracks: List.from(tracks),
      activeTabId: activeTabId,
      expandedRoadmapNodes: Map.from(expandedRoadmapNodes),
      lastVideoTimestampSeconds: lastVideoTimestampSeconds,
    );
  }
}
