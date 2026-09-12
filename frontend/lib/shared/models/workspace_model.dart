import 'package:flutter/material.dart';
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
      activeTabId: activeTabId,
      expandedRoadmapNodes: Map.from(expandedRoadmapNodes),
      lastVideoTimestampSeconds: lastVideoTimestampSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'subject': subject,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      'lastOpened': lastOpened.toIso8601String(),
      'progressPercent': progressPercent,
      'activeLearningContext': activeLearningContext,
      'flashcardCount': flashcardCount,
      'roadmapNodeCount': roadmapNodeCount,
      'accentColor': accentColor.toARGB32(),
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isCourseConfirmed': isCourseConfirmed,
      'activeTabId': activeTabId,
      'lastVideoTimestampSeconds': lastVideoTimestampSeconds,
      'persona': persona?.toJson(),
      'subjectCluster': subjectCluster?.toJson(),
      'roadmap': roadmap.map((e) => e.toJson()).toList(),
      'flashcards': flashcards.map((e) => e.toJson()).toList(),
      'chatHistory': chatHistory.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      difficulty: json['difficulty'] ?? 'Beginner',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      lastOpened: json['lastOpened'] != null ? DateTime.parse(json['lastOpened']) : DateTime.now(),
      progressPercent: (json['progressPercent'] ?? 0.0).toDouble(),
      activeLearningContext: json['activeLearningContext'] ?? '',
      flashcardCount: json['flashcardCount'] ?? 0,
      roadmapNodeCount: json['roadmapNodeCount'] ?? 0,
      accentColor: json['accentColor'] != null ? Color(json['accentColor']) : const Color(0xFF67E8F9),
      isPinned: json['isPinned'] ?? false,
      isArchived: json['isArchived'] ?? false,
      isCourseConfirmed: json['isCourseConfirmed'] ?? false,
      activeTabId: json['activeTabId'] ?? 'roadmap',
      lastVideoTimestampSeconds: json['lastVideoTimestampSeconds'] ?? 0,
      persona: json['persona'] != null ? PersonaProfile.fromJson(json['persona']) : null,
      subjectCluster: json['subjectCluster'] != null ? SubjectCluster.fromJson(json['subjectCluster']) : null,
      roadmap: (json['roadmap'] as List<dynamic>?)?.map<RoadmapNode>((e) => RoadmapNode.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      flashcards: (json['flashcards'] as List<dynamic>?)?.map<FlashcardItem>((e) => FlashcardItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      chatHistory: (json['chatHistory'] as List<dynamic>?)
              ?.map<ChatMessage>((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
