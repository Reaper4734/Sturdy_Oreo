import '../../../shared/models/mastery_test_model.dart';

enum ViolationType {
  tabSwitch,
  windowBlur,
  shortcutViolation,
  clipboardCopy,
  clipboardPaste,
  devtoolsOpened,
  faceOcclusion,
  audioAnomaly,
}

enum ExamIntegrityTier {
  verifiedHonors, // >= 85% trust
  standardPass,   // 60-84% trust
  flaggedReview,  // < 60% trust
  disqualified,   // 3 strikes
}

enum MarkingScheme {
  standard,          // +1 correct, 0 incorrect, 0 skipped
  negativePenalty,   // +4 correct, -1 incorrect, 0 skipped
  difficultyWeighted,// +1 easy, +2 medium, +3 hard
  hybridUniversity,  // University Exam: Section A (MCQs) + Section B (Subjective Problems)
}

extension MarkingSchemeExt on MarkingScheme {
  String get label {
    switch (this) {
      case MarkingScheme.standard:
        return 'Standard (+1 / 0)';
      case MarkingScheme.negativePenalty:
        return 'Competitive Negative (+4 / -1)';
      case MarkingScheme.difficultyWeighted:
        return 'Honors Weighted (+1 to +3)';
      case MarkingScheme.hybridUniversity:
        return 'University Hybrid (Objective + Subjective)';
    }
  }

  String get apiKey {
    switch (this) {
      case MarkingScheme.standard:
        return 'STANDARD';
      case MarkingScheme.negativePenalty:
        return 'NEGATIVE_PENALTY';
      case MarkingScheme.difficultyWeighted:
        return 'DIFFICULTY_WEIGHTED';
      case MarkingScheme.hybridUniversity:
        return 'HYBRID_UNIVERSITY';
    }
  }

  String get shortTag {
    switch (this) {
      case MarkingScheme.standard:
        return '+1 / 0';
      case MarkingScheme.negativePenalty:
        return '+4 / -1';
      case MarkingScheme.difficultyWeighted:
        return 'Weighted';
      case MarkingScheme.hybridUniversity:
        return 'University 100M';
    }
  }

  String get description {
    switch (this) {
      case MarkingScheme.standard:
        return '+1 mark for correct answers. No penalty for wrong answers.';
      case MarkingScheme.negativePenalty:
        return '+4 marks for correct, -1 mark penalty for incorrect. Zero for unattempted.';
      case MarkingScheme.difficultyWeighted:
        return 'Difficulty scaled marks (+1 to +3). No penalty for wrong answers.';
      case MarkingScheme.hybridUniversity:
        return 'Section A: Objective Concepts. Section B: Subjective Architecture & Code (15 Marks each).';
    }
  }
}

class ExamViolation {
  final DateTime timestamp;
  final ViolationType type;
  final String title;
  final String details;
  final double trustPenalty;

  const ExamViolation({
    required this.timestamp,
    required this.type,
    required this.title,
    required this.details,
    required this.trustPenalty,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'title': title,
    'details': details,
    'trustPenalty': trustPenalty,
  };
}

class SubjectiveEvaluation {
  final String questionId;
  final String topicTag;
  final double scorePercent;
  final double marksEarned;
  final double maxMarks;
  final String feedback;
  final String? suggestedReviewTopic;

  const SubjectiveEvaluation({
    required this.questionId,
    required this.topicTag,
    required this.scorePercent,
    required this.marksEarned,
    required this.maxMarks,
    required this.feedback,
    this.suggestedReviewTopic,
  });

  factory SubjectiveEvaluation.fromJson(Map<String, dynamic> json) {
    return SubjectiveEvaluation(
      questionId: json['questionId'] ?? '',
      topicTag: json['topicTag'] ?? '',
      scorePercent: (json['scorePercent'] as num?)?.toDouble() ?? 0.0,
      marksEarned: (json['marksEarned'] as num?)?.toDouble() ?? 0.0,
      maxMarks: (json['maxMarks'] as num?)?.toDouble() ?? 15.0,
      feedback: json['feedback'] ?? '',
      suggestedReviewTopic: json['suggestedReviewTopic'],
    );
  }
}

class ExamSessionModel {
  final String sessionId;
  final String workspaceId;
  final String courseTitle;
  final String domain;
  final int durationMinutes;
  final DateTime startTime;
  final List<QuestionItem> questions;
  final Map<String, String> userAnswers;
  final Set<String> flaggedQuestionIds;
  final MarkingScheme markingScheme;
  final int passingPercent;
  int totalTargetQuestions;
  bool isGenerating;
  double trustScore;
  int strikeCount;
  final List<ExamViolation> violations;
  bool isCompleted;
  bool isDisqualified;

  ExamSessionModel({
    required this.sessionId,
    required this.workspaceId,
    required this.courseTitle,
    required this.domain,
    this.durationMinutes = 15,
    required this.startTime,
    required this.questions,
    int? totalTargetQuestions,
    this.isGenerating = false,
    Map<String, String>? userAnswers,
    Set<String>? flaggedQuestionIds,
    this.markingScheme = MarkingScheme.hybridUniversity,
    this.passingPercent = 60,
    this.trustScore = 100.0,
    this.strikeCount = 0,
    List<ExamViolation>? violations,
    this.isCompleted = false,
    this.isDisqualified = false,
  })  : totalTargetQuestions = totalTargetQuestions ?? questions.length,
        userAnswers = userAnswers ?? {},
        flaggedQuestionIds = flaggedQuestionIds ?? {},
        violations = violations ?? [];

  ExamIntegrityTier get integrityTier {
    if (isDisqualified || strikeCount >= 3) return ExamIntegrityTier.disqualified;
    if (trustScore >= 85) return ExamIntegrityTier.verifiedHonors;
    if (trustScore >= 60) return ExamIntegrityTier.standardPass;
    return ExamIntegrityTier.flaggedReview;
  }
}

class ExamCertificate {
  final String certificateId;
  final String learnerName;
  final String courseTitle;
  final double scorePercent;
  final double trustScore;
  final int correctAnswers;
  final int totalQuestions;
  final double marksEarned;
  final double totalMarksAvailable;
  final MarkingScheme markingScheme;
  final List<SubjectiveEvaluation> evaluations;
  final DateTime issueDate;
  final ExamIntegrityTier tier;
  final int xpEarned;

  const ExamCertificate({
    required this.certificateId,
    required this.learnerName,
    required this.courseTitle,
    required this.scorePercent,
    required this.trustScore,
    required this.correctAnswers,
    required this.totalQuestions,
    this.marksEarned = 0,
    this.totalMarksAvailable = 0,
    this.markingScheme = MarkingScheme.hybridUniversity,
    this.evaluations = const [],
    required this.issueDate,
    required this.tier,
    required this.xpEarned,
  });
}
