import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/mastery_test_model.dart';
import '../models/proctored_exam_model.dart';

class ExamQuestionsUpdate {
  final String sessionId;
  final int totalTargetQuestions;
  final bool isGenerating;
  final List<QuestionItem> questions;

  const ExamQuestionsUpdate({
    required this.sessionId,
    required this.totalTargetQuestions,
    required this.isGenerating,
    required this.questions,
  });
}

class HttpProctoredExamRepository {
  final ApiClient _apiClient = ApiClient();

  List<QuestionItem> _parseQuestions(List rawQuestions, String courseTitle) {
    return rawQuestions.map((q) {
      final typeStr = (q['type'] as String?)?.toLowerCase();
      final qType = typeStr == 'subjective'
          ? QuestionType.subjective
          : (typeStr == 'code' ? QuestionType.codeTerminal : QuestionType.longMcq);

      final options = (q['options'] as List? ?? []).map((o) => QuestionnaireOption(
        id: o['id'] ?? 'opt_${DateTime.now().microsecondsSinceEpoch}',
        text: o['text'] ?? '',
        isCorrect: o['isCorrect'] ?? false,
        explanation: o['explanation'],
      )).toList();

      return QuestionItem(
        id: q['id'] ?? 'q_${DateTime.now().microsecondsSinceEpoch}',
        topicTag: q['topicTag'] ?? courseTitle,
        questionText: q['questionText'] ?? '',
        type: qType,
        options: options,
      );
    }).toList();
  }

  Future<ExamSessionModel> startExam({
    required String workspaceId,
    required String courseTitle,
    required String domain,
    int durationMinutes = 15,
    MarkingScheme markingScheme = MarkingScheme.hybridUniversity,
  }) async {
    try {
      final response = await _apiClient.post('/exam/start', body: {
        'workspaceId': workspaceId,
        'courseTitle': courseTitle,
        'domain': domain,
        'durationMinutes': durationMinutes,
        'markingScheme': markingScheme.apiKey,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawQuestions = data['questions'] as List? ?? [];
        final questions = _parseQuestions(rawQuestions, courseTitle);
        final totalTarget = data['totalTargetQuestions'] as int? ?? questions.length;
        final isGenerating = data['isGenerating'] as bool? ?? false;

        return ExamSessionModel(
          sessionId: data['sessionId'] ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
          workspaceId: workspaceId,
          courseTitle: courseTitle,
          domain: domain,
          durationMinutes: data['durationMinutes'] ?? durationMinutes,
          markingScheme: markingScheme,
          totalTargetQuestions: totalTarget,
          isGenerating: isGenerating,
          startTime: DateTime.tryParse(data['startTime'] ?? '') ?? DateTime.now(),
          questions: questions,
        );
      }
    } catch (e) {
      // Fallback gracefully to offline session
    }

    return _createOfflineFallbackSession(workspaceId, courseTitle, domain, durationMinutes, markingScheme);
  }

  Future<ExamQuestionsUpdate?> fetchExamQuestions(
    String sessionId, {
    String courseTitle = 'Software Architecture',
  }) async {
    try {
      final response = await _apiClient.get('/exam/$sessionId/questions');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawQuestions = data['questions'] as List? ?? [];
        final questions = _parseQuestions(rawQuestions, courseTitle);
        return ExamQuestionsUpdate(
          sessionId: data['sessionId'] ?? sessionId,
          totalTargetQuestions: data['totalTargetQuestions'] as int? ?? questions.length,
          isGenerating: data['isGenerating'] as bool? ?? false,
          questions: questions,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> recordTelemetry(
    String sessionId, {
    required ExamViolation violation,
    required double trustScore,
    required int strikeCount,
  }) async {
    try {
      await _apiClient.post('/exam/$sessionId/telemetry', body: {
        'violation': violation.toJson(),
        'trustScore': trustScore,
        'strikeCount': strikeCount,
      });
    } catch (_) {
      // Best-effort telemetry recording
    }
  }

  Future<ExamCertificate> submitExam(
    String sessionId, {
    required String courseTitle,
    required Map<String, String> answers,
    required double trustScore,
    required int strikeCount,
    required int timeSpentSeconds,
    required List<QuestionItem> questions,
    MarkingScheme markingScheme = MarkingScheme.hybridUniversity,
  }) async {
    try {
      final response = await _apiClient.post('/exam/$sessionId/submit', body: {
        'answers': answers,
        'trustScore': trustScore,
        'strikeCount': strikeCount,
        'timeSpentSeconds': timeSpentSeconds,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tierStr = data['tier'] ?? 'STANDARD_PASS';
        ExamIntegrityTier tier = ExamIntegrityTier.standardPass;
        if (tierStr == 'DISQUALIFIED') {
          tier = ExamIntegrityTier.disqualified;
        } else if (tierStr == 'FIRST_CLASS_HONORS' || tierStr == 'VERIFIED_HONORS') {
          tier = ExamIntegrityTier.verifiedHonors;
        } else if (tierStr == 'FLAGGED_REVIEW') {
          tier = ExamIntegrityTier.flaggedReview;
        }

        final rawEvals = data['evaluations'] as List? ?? [];
        final evaluations = rawEvals
            .map((e) => SubjectiveEvaluation.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        return ExamCertificate(
          certificateId: data['certificateId'] ?? 'OREO-UNIV-GEN',
          learnerName: data['learnerName'] ?? 'Learner',
          courseTitle: data['courseTitle'] ?? courseTitle,
          scorePercent: (data['scorePercent'] as num?)?.toDouble() ?? 80.0,
          trustScore: (data['trustScore'] as num?)?.toDouble() ?? trustScore,
          correctAnswers: data['correctAnswers'] ?? answers.length,
          totalQuestions: data['totalQuestions'] ?? questions.length,
          marksEarned: (data['marksEarned'] as num?)?.toDouble() ?? 0.0,
          totalMarksAvailable: (data['totalMarksAvailable'] as num?)?.toDouble() ?? 100.0,
          markingScheme: markingScheme,
          evaluations: evaluations,
          issueDate: DateTime.tryParse(data['issueDate'] ?? '') ?? DateTime.now(),
          tier: tier,
          xpEarned: data['xpEarned'] ?? 250,
        );
      }
    } catch (_) {
      // Offline fallback computation
    }

    return _computeLocalCertificate(
      courseTitle: courseTitle,
      answers: answers,
      trustScore: trustScore,
      strikeCount: strikeCount,
      questions: questions,
      markingScheme: markingScheme,
    );
  }

  ExamSessionModel _createOfflineFallbackSession(
    String workspaceId,
    String courseTitle,
    String domain,
    int durationMinutes,
    MarkingScheme markingScheme,
  ) {
    int targetMcq;
    int targetSubjective;
    if (durationMinutes <= 15) {
      targetMcq = 3;
      targetSubjective = 2;
    } else if (durationMinutes <= 30) {
      targetMcq = 7;
      targetSubjective = 3;
    } else if (durationMinutes <= 60) {
      targetMcq = 14;
      targetSubjective = 6;
    } else if (durationMinutes <= 120) {
      targetMcq = 25;
      targetSubjective = 10;
    } else {
      targetMcq = 35;
      targetSubjective = 15;
    }
    final totalTarget = targetMcq + targetSubjective;

    final baseBank = [
      QuestionItem(
        id: 'q_obj_1',
        topicTag: 'Architecture Patterns',
        questionText: 'In $courseTitle, what is the primary benefit of maintaining strict dependency contracts between modules?',
        type: QuestionType.longMcq,
        options: [
          const QuestionnaireOption(id: 'opt_1', text: 'Coupling components directly via global static variables', isCorrect: false),
          const QuestionnaireOption(id: 'opt_2', text: 'Isolation of concerns, easier unit testing, and modular replacement', isCorrect: true, explanation: 'Decoupled contracts allow isolated component testing and independent deployment.'),
          const QuestionnaireOption(id: 'opt_3', text: 'Elimination of all network latency automatically', isCorrect: false),
          const QuestionnaireOption(id: 'opt_4', text: 'Automatic code compilation without type checkers', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_obj_2',
        topicTag: 'Security & Integrity',
        questionText: 'Which client behavior indicates potential academic dishonesty during a proctored assessment?',
        type: QuestionType.longMcq,
        options: [
          const QuestionnaireOption(id: 'opt_2a', text: 'Rapid keyboard navigation using standard Arrow keys', isCorrect: false),
          const QuestionnaireOption(id: 'opt_2b', text: 'Repeated window defocusing, devtools invocation, or clipboard exfiltration', isCorrect: true, explanation: 'Unfocused windows and clipboard manipulation are characteristic indicators of external assistance.'),
          const QuestionnaireOption(id: 'opt_2c', text: 'Reviewing flagged questions prior to final submission', isCorrect: false),
          const QuestionnaireOption(id: 'opt_2d', text: 'Adjusting ambient microphone gain levels', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_obj_3',
        topicTag: 'Concurrency & Event Loops',
        questionText: 'How do modern concurrent web servers prevent thread pool exhaustion under spike loads?',
        type: QuestionType.longMcq,
        options: [
          const QuestionnaireOption(id: 'opt_3a', text: 'Asynchronous non-blocking event loops and bounded connection pools', isCorrect: true, explanation: 'Non-blocking I/O event loops reuse thread pools without blocking on socket reads.'),
          const QuestionnaireOption(id: 'opt_3b', text: 'Spawning unmanaged OS threads per request', isCorrect: false),
          const QuestionnaireOption(id: 'opt_3c', text: 'Restarting the container process every 10 seconds', isCorrect: false),
          const QuestionnaireOption(id: 'opt_3d', text: 'Dropping 50% of incoming TCP packets indiscriminately', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_obj_4',
        topicTag: 'Database Indexing',
        questionText: 'Why are B-Tree indexes preferred over Hash indexes for relational database range queries?',
        type: QuestionType.longMcq,
        options: [
          const QuestionnaireOption(id: 'opt_4a', text: 'B-Trees maintain sorted order enabling O(log N) scans for interval ranges (<, <=, BETWEEN)', isCorrect: true, explanation: 'B-Trees keep keys sorted, enabling logarithmic range seeking.'),
          const QuestionnaireOption(id: 'opt_4b', text: 'Hash indexes cannot store integers', isCorrect: false),
          const QuestionnaireOption(id: 'opt_4c', text: 'B-Trees require zero disk allocations', isCorrect: false),
          const QuestionnaireOption(id: 'opt_4d', text: 'Hash indexes only support primary keys', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_sub_1',
        topicTag: 'Distributed Systems & Queue Design',
        questionText: '[15 MARKS] Design a high-throughput, fault-tolerant messaging and ingestion pipeline for $courseTitle.\n\nAddress the following in your response:\n(a) Describe your consumer group and partition distribution strategy.\n(b) Contrast exactly-once processing vs. at-least-once with idempotency keys.\n(c) Provide a Dead-Letter Queue (DLQ) retry and exponential backoff implementation pattern (pseudocode or architecture narrative).',
        type: QuestionType.subjective,
        options: const [],
      ),
      QuestionItem(
        id: 'q_sub_2',
        topicTag: 'Concurrency & Resource Optimization',
        questionText: '[15 MARKS] Analyze connection pool starvation and database thread exhaustion in high-concurrency Spring Boot applications.\n\nAddress:\n(a) Root causes: Long-running transactions vs. thread pool starvation.\n(b) Mitigation: Configure HikariCP connection pool settings (maximumPoolSize, connectionTimeout, leakDetectionThreshold).\n(c) Write a concise Java or pseudo-code configuration illustrating a non-blocking query fallback pattern.',
        type: QuestionType.subjective,
        options: const [],
      ),
    ];

    final questions = <QuestionItem>[];
    for (int i = 0; i < totalTarget; i++) {
      if (i < baseBank.length) {
        questions.add(baseBank[i]);
      } else {
        final isSub = (i % 3 == 0);
        questions.add(
          isSub
              ? QuestionItem(
                  id: 'q_sub_${i + 1}',
                  topicTag: 'System Scalability #${i + 1}',
                  questionText: '[15 MARKS] Analyze architectural resilience and fault-tolerance tradeoffs for component module #${i + 1} in $courseTitle.\n\nAddress:\n(a) High-availability failover topology.\n(b) Data consistency mechanisms and replication constraints.\n(c) Remediation patterns for degraded network partitions.',
                  type: QuestionType.subjective,
                  options: const [],
                )
              : QuestionItem(
                  id: 'q_obj_${i + 1}',
                  topicTag: 'Engineering Core Concept #${i + 1}',
                  questionText: 'In $courseTitle (Module ${i + 1}), which design pattern best encapsulates domain business rules and protects invariants?',
                  type: QuestionType.longMcq,
                  options: [
                    QuestionnaireOption(id: 'opt_${i}_1', text: 'Aggregate Roots and Rich Domain Models', isCorrect: true, explanation: 'Aggregate roots encapsulate internal entities and enforce invariants.'),
                    QuestionnaireOption(id: 'opt_${i}_2', text: 'Exposing all database tables through public static setters', isCorrect: false),
                    QuestionnaireOption(id: 'opt_${i}_3', text: 'Writing all logic inside raw SQL stored procedures only', isCorrect: false),
                    QuestionnaireOption(id: 'opt_${i}_4', text: 'Directly modifying bytecode in production runtime', isCorrect: false),
                  ],
                ),
        );
      }
    }

    return ExamSessionModel(
      sessionId: 'session_local_${DateTime.now().millisecondsSinceEpoch}',
      workspaceId: workspaceId,
      courseTitle: courseTitle,
      domain: domain,
      durationMinutes: durationMinutes,
      markingScheme: markingScheme,
      totalTargetQuestions: totalTarget,
      isGenerating: false,
      startTime: DateTime.now(),
      questions: questions,
    );
  }

  ExamCertificate _computeLocalCertificate({
    required String courseTitle,
    required Map<String, String> answers,
    required double trustScore,
    required int strikeCount,
    required List<QuestionItem> questions,
    required MarkingScheme markingScheme,
  }) {
    int correctCount = 0;
    double marksEarned = 0.0;
    double totalMarks = 0.0;
    final List<SubjectiveEvaluation> evals = [];

    for (final q in questions) {
      final userAns = answers[q.id];
      if (q.type == QuestionType.subjective) {
        totalMarks += 15.0;
        if (userAns != null && userAns.trim().length >= 15) {
          marksEarned += 12.0;
          correctCount++;
          evals.add(SubjectiveEvaluation(
            questionId: q.id,
            topicTag: q.topicTag,
            scorePercent: 80.0,
            marksEarned: 12.0,
            maxMarks: 15.0,
            feedback: 'Solid technical response addressing key architectural criteria.',
          ));
        } else {
          evals.add(SubjectiveEvaluation(
            questionId: q.id,
            topicTag: q.topicTag,
            scorePercent: 0.0,
            marksEarned: 0.0,
            maxMarks: 15.0,
            feedback: 'Incomplete or unattempted question.',
          ));
        }
      } else {
        totalMarks += 1.0;
        if (userAns != null) {
          for (final opt in q.options) {
            if (opt.isCorrect && (opt.id == userAns || opt.text == userAns)) {
              correctCount++;
              marksEarned += 1.0;
              break;
            }
          }
        }
      }
    }

    final total = questions.isEmpty ? 1 : questions.length;
    final score = totalMarks > 0 ? (marksEarned / totalMarks) * 100.0 : (correctCount / total) * 100.0;
    final isDisqualified = strikeCount >= 3;

    ExamIntegrityTier tier;
    if (isDisqualified) {
      tier = ExamIntegrityTier.disqualified;
    } else if (trustScore >= 85 && score >= 75) {
      tier = ExamIntegrityTier.verifiedHonors;
    } else if (trustScore >= 60 && score >= 50) {
      tier = ExamIntegrityTier.standardPass;
    } else {
      tier = ExamIntegrityTier.flaggedReview;
    }

    return ExamCertificate(
      certificateId: 'OREO-UNIV-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}',
      learnerName: 'Learner',
      courseTitle: courseTitle,
      scorePercent: score,
      trustScore: trustScore,
      correctAnswers: correctCount,
      totalQuestions: total,
      marksEarned: marksEarned,
      totalMarksAvailable: totalMarks,
      markingScheme: markingScheme,
      evaluations: evals,
      issueDate: DateTime.now(),
      tier: tier,
      xpEarned: isDisqualified ? 0 : (200 + (score * 1.5).round()),
    );
  }
}

final httpProctoredExamRepositoryProvider = Provider((ref) => HttpProctoredExamRepository());
