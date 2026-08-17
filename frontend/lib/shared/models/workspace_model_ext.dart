import 'package:flutter/material.dart';
import 'workspace_model.dart';
import 'mind_map_model.dart';
import 'roadmap_model.dart';
import 'persona_model.dart';
import 'flashcard_model.dart';

extension WorkspaceModelSerialization on WorkspaceModel {
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
    };
  }

  static WorkspaceModel fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'],
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
    );
  }
}
