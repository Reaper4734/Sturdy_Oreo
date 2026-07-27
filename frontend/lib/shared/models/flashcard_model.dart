import 'package:flutter/material.dart';

enum FlashcardType { basic, fillBlank, codeSnippet }
enum StudyMode { browse, quiz, shuffle }

class FlashcardItem {
  final String id;
  final String front;
  final String back;
  final String topicTag;
  final FlashcardType type;
  final List<String> tags;
  String? userAnnotation;
  DateTime? nextReviewDate;
  int intervalDays;
  double easeFactor;
  int consecutiveCorrect;
  int totalReviews;
  bool isFlipped;
  bool isBookmarked;
  Offset position;

  FlashcardItem({
    required this.id,
    required this.front,
    required this.back,
    required this.topicTag,
    this.type = FlashcardType.basic,
    this.tags = const [],
    this.userAnnotation,
    this.nextReviewDate,
    this.intervalDays = 1,
    this.easeFactor = 2.5,
    this.consecutiveCorrect = 0,
    this.totalReviews = 0,
    this.isFlipped = false,
    this.isBookmarked = false,
    this.position = const Offset(100, 100),
  });

  Color get confidenceColor {
    if (easeFactor < 2.0) {
      return const Color(0xFFEF4444); // Red - struggling
    } else if (easeFactor <= 2.5) {
      return const Color(0xFFF59E0B); // Amber - learning
    } else {
      return const Color(0xFF10B981); // Emerald - mastered
    }
  }

  String get confidenceLabel {
    if (easeFactor < 2.0) {
      return 'Struggling';
    } else if (easeFactor <= 2.5) {
      return 'Learning';
    } else {
      return 'Mastered';
    }
  }

  int get leitnerBox {
    if (consecutiveCorrect <= 0) return 1;
    if (consecutiveCorrect == 1) return 2;
    if (consecutiveCorrect == 2) return 3;
    if (consecutiveCorrect == 3) return 4;
    return 5;
  }

  bool get isDue {
    if (nextReviewDate == null) return true;
    return DateTime.now().isAfter(nextReviewDate!);
  }
}

class CardConnection {
  final String fromId;
  final String toId;

  CardConnection({required this.fromId, required this.toId});
}
