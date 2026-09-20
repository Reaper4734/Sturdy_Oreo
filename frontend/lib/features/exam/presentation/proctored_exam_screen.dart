import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/models/mastery_test_model.dart';
import '../../../shared/providers/workspace_providers.dart';
import '../data/http_proctored_exam_repository.dart';
import '../models/proctored_exam_model.dart';
import '../services/exam_anti_cheat_sentinel.dart';
import 'widgets/exam_completion_certificate_dialog.dart';
import 'widgets/exam_question_matrix.dart';
import 'widgets/proctored_exam_top_bar.dart';
import 'widgets/violation_warning_dialog.dart';
import 'widgets/webcam_proctor_hud.dart';

class ProctoredExamScreen extends ConsumerStatefulWidget {
  final VoidCallback? onExit;
  final int durationMinutes;
  final MarkingScheme markingScheme;

  const ProctoredExamScreen({
    super.key,
    this.onExit,
    this.durationMinutes = 30,
    this.markingScheme = MarkingScheme.hybridUniversity,
  });

  @override
  ConsumerState<ProctoredExamScreen> createState() => _ProctoredExamScreenState();
}

class _ProctoredExamScreenState extends ConsumerState<ProctoredExamScreen> {
  ExamSessionModel? _session;
  bool _isLoading = true;
  int _currentIndex = 0;
  int _remainingSeconds = 1800; // 30 min default
  Timer? _countdownTimer;
  Timer? _questionsPollingTimer;
  ExamAntiCheatSentinel? _sentinel;
  bool _isViolating = false;
  ExamViolation? _latestViolation;
  bool _isSubmitting = false;

  final Map<String, TextEditingController> _subjectiveControllers = {};
  final Map<String, String> _lastKnownAnswers = {};

  @override
  void initState() {
    super.initState();
    _initExamSession();
  }

  Future<void> _initExamSession() async {
    final activeWs = ref.read(activeWorkspaceProvider);
    final courseTitle = activeWs?.title.isNotEmpty == true
        ? activeWs!.title
        : (activeWs?.subject.isNotEmpty == true ? activeWs!.subject : 'Software Architecture Capstone');
    final domain = activeWs?.subject.isNotEmpty == true ? activeWs!.subject : 'Computer Science';
    final wsId = activeWs?.id ?? 'ws_default';

    final repo = ref.read(httpProctoredExamRepositoryProvider);
    final session = await repo.startExam(
      workspaceId: wsId,
      courseTitle: courseTitle,
      domain: domain,
      durationMinutes: widget.durationMinutes,
      markingScheme: widget.markingScheme,
    );

    if (!mounted) return;

    setState(() {
      _session = session;
      _remainingSeconds = session.durationMinutes * 60;
      _isLoading = false;
    });

    _startTimer();
    _startAntiCheatSentinel();

    if (_session!.isGenerating || _session!.questions.length < _session!.totalTargetQuestions) {
      _startQuestionPolling();
    }
  }

  void _startQuestionPolling() {
    _questionsPollingTimer?.cancel();
    _questionsPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _session == null) {
        timer.cancel();
        return;
      }
      if (!_session!.isGenerating && _session!.questions.length >= _session!.totalTargetQuestions) {
        timer.cancel();
        return;
      }

      final repo = ref.read(httpProctoredExamRepositoryProvider);
      final update = await repo.fetchExamQuestions(_session!.sessionId, courseTitle: _session!.courseTitle);
      if (!mounted || update == null) return;

      if (update.questions.length > _session!.questions.length || _session!.isGenerating != update.isGenerating) {
        setState(() {
          _session!.questions.clear();
          _session!.questions.addAll(update.questions);
          _session!.totalTargetQuestions = update.totalTargetQuestions;
          _session!.isGenerating = update.isGenerating;
        });
      }

      if (!update.isGenerating && update.questions.length >= update.totalTargetQuestions) {
        timer.cancel();
      }
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _countdownTimer?.cancel();
          _handleSubmit(autoSubmit: true);
        }
      });
    });
  }

  void _startAntiCheatSentinel() {
    _sentinel = ExamAntiCheatSentinel(
      onViolation: (violation) {
        if (!mounted || _session == null) return;
        setState(() {
          _isViolating = true;
          _latestViolation = violation;
          _session!.trustScore = _sentinel!.trustScore;
          _session!.violations.add(violation);
        });

        // Report telemetry to backend asynchronously
        ref.read(httpProctoredExamRepositoryProvider).recordTelemetry(
          _session!.sessionId,
          violation: violation,
          trustScore: _sentinel!.trustScore,
          strikeCount: _sentinel!.strikeCount,
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isViolating = false);
        });
      },
      onStrike: (strikeCount, message) {
        if (!mounted || _session == null) return;
        setState(() {
          _session!.strikeCount = strikeCount;
        });

        ViolationWarningDialog.show(
          context,
          violation: _latestViolation,
          strikeCount: strikeCount,
          isDisqualified: false,
          onDismiss: () {},
        );
      },
      onDisqualified: () {
        if (!mounted || _session == null) return;
        setState(() {
          _session!.isDisqualified = true;
          _session!.strikeCount = 3;
        });

        ViolationWarningDialog.show(
          context,
          violation: _latestViolation,
          strikeCount: 3,
          isDisqualified: true,
          onDismiss: () {
            _handleSubmit(autoSubmit: true);
          },
        );
      },
    );

    _sentinel!.startMonitoring();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _questionsPollingTimer?.cancel();
    _sentinel?.dispose();
    for (final c in _subjectiveControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectAnswer(String questionId, String optionId) {
    if (_session == null) return;
    setState(() {
      _session!.userAnswers[questionId] = optionId;
    });
  }

  void _toggleFlag(String questionId) {
    if (_session == null) return;
    setState(() {
      if (_session!.flaggedQuestionIds.contains(questionId)) {
        _session!.flaggedQuestionIds.remove(questionId);
      } else {
        _session!.flaggedQuestionIds.add(questionId);
      }
    });
  }

  TextEditingController _getSubjectiveController(String questionId) {
    if (!_subjectiveControllers.containsKey(questionId)) {
      final initialText = _session?.userAnswers[questionId] ?? '';
      _lastKnownAnswers[questionId] = initialText;
      final controller = TextEditingController(text: initialText);
      controller.addListener(() {
        if (_session != null) {
          _session!.userAnswers[questionId] = controller.text;
        }
      });
      _subjectiveControllers[questionId] = controller;
    }
    return _subjectiveControllers[questionId]!;
  }

  Future<void> _handleSubmit({bool autoSubmit = false}) async {
    if (_isSubmitting || _session == null) return;
    _isSubmitting = true;
    _countdownTimer?.cancel();
    _questionsPollingTimer?.cancel();
    _sentinel?.stopMonitoring();

    final repo = ref.read(httpProctoredExamRepositoryProvider);
    final cert = await repo.submitExam(
      _session!.sessionId,
      courseTitle: _session!.courseTitle,
      answers: _session!.userAnswers,
      trustScore: _session!.trustScore,
      strikeCount: _session!.strikeCount,
      timeSpentSeconds: (_session!.durationMinutes * 60) - _remainingSeconds,
      questions: _session!.questions,
      markingScheme: _session!.markingScheme,
    );

    // Update active workspace progress
    final activeWs = ref.read(activeWorkspaceProvider);
    if (activeWs != null && !_session!.isDisqualified) {
      activeWs.progressPercent = 1.0;
      ref.read(workspaceListProvider.notifier).updateWorkspace(activeWs);
    }

    if (!mounted) return;

    ExamCompletionCertificateDialog.show(
      context,
      certificate: cert,
      onClose: () {
        widget.onExit?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading || _session == null) {
      return Scaffold(
        backgroundColor: colors.bgCanvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colors.accentCyan),
              const SizedBox(height: 16),
              Text(
                'INITIALIZING UNIVERSITY PROCTORED EXAMINATION...',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: colors.fgSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final questions = _session!.questions;
    final totalTarget = _session!.totalTargetQuestions;
    final currentQ = questions.isNotEmpty && _currentIndex < questions.length
        ? questions[_currentIndex]
        : null;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          // Only use digit hotkeys for MCQ questions
          if (event is KeyDownEvent && currentQ != null && currentQ.type != QuestionType.subjective && currentQ.options.isNotEmpty) {
            final key = event.logicalKey;
            int? optIndex;
            if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) optIndex = 0;
            if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) optIndex = 1;
            if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) optIndex = 2;
            if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) optIndex = 3;

            if (optIndex != null && optIndex < currentQ.options.length) {
              _selectAnswer(currentQ.id, currentQ.options[optIndex].id);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            // Top Proctored Exam Command Bar
            ProctoredExamTopBar(
              courseTitle: _session!.courseTitle,
              remainingSeconds: _remainingSeconds,
              trustScore: _session!.trustScore,
              strikeCount: _session!.strikeCount,
              onSubmit: () => _handleSubmit(autoSubmit: false),
            ),

            // Main Interactive Exam Workspace
            Expanded(
              child: Row(
                children: [
                  // Left / Center: Question Viewport (Subjective, Objective, or AI Synthesis Placeholder)
                  Expanded(
                    flex: 7,
                    child: _buildQuestionViewport(currentQ, totalTarget, colors),
                  ),

                  // Right: Proctoring Telemetry HUD & Question Navigator Matrix
                  Container(
                    width: 320,
                    decoration: BoxDecoration(
                      color: colors.bgActivityBar,
                      border: Border(left: BorderSide(color: colors.borderSubtle, width: 0.8)),
                    ),
                    child: Column(
                      children: [
                        // Live Webcam Proctoring HUD
                        WebcamProctorHud(
                          isViolating: _isViolating,
                          strikeCount: _session!.strikeCount,
                          trustScore: _session!.trustScore,
                          onAudioAnomaly: (db) => _sentinel?.reportAudioAnomaly(db),
                          onBiometrics: (t) => _sentinel?.reportBiometricTelemetry(t),
                        ),

                        // Question Matrix Sidebar Navigator
                        Expanded(
                          child: ExamQuestionMatrix(
                            questions: questions,
                            totalTargetQuestions: totalTarget,
                            isGenerating: _session!.isGenerating,
                            currentIndex: _currentIndex,
                            userAnswers: _session!.userAnswers,
                            flaggedQuestionIds: _session!.flaggedQuestionIds,
                            onSelectQuestion: (index) {
                              setState(() => _currentIndex = index);
                            },
                            onToggleFlag: _toggleFlag,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionViewport(
    QuestionItem? question,
    int totalQuestions,
    AppColorsExtension colors,
  ) {
    if (question == null) {
      return _buildQuestionGeneratingPlaceholder(_currentIndex, totalQuestions, colors);
    }

    final isSubjective = question.type == QuestionType.subjective;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section & Topic Pill Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSubjective
                      ? colors.accentAmber.withValues(alpha: 0.15)
                      : colors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSubjective ? colors.accentAmber : colors.accentCyan,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isSubjective
                      ? 'SECTION B: SUBJECTIVE PROBLEM [15 MARKS]'
                      : 'SECTION A: OBJECTIVE CONCEPT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isSubjective ? colors.accentAmber : colors.accentCyan,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'QUESTION ${_currentIndex + 1} OF $totalQuestions • ${question.topicTag}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.fgSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Prompt Statement
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: colors.fgPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Content Area: Subjective Answer Sheet OR Objective Options List
          Expanded(
            child: isSubjective
                ? _buildSubjectiveAnswerSheet(question, colors)
                : _buildObjectiveOptionsList(question, colors),
          ),

          const SizedBox(height: 16),

          // Bottom Step Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              OutlinedButton.icon(
                onPressed: _currentIndex > 0
                    ? () => setState(() => _currentIndex--)
                    : null,
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text('Previous', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.fgPrimary,
                  side: BorderSide(color: colors.borderSubtle, width: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              // Flag current question button
              TextButton.icon(
                onPressed: () => _toggleFlag(question.id),
                icon: Icon(
                  _session!.flaggedQuestionIds.contains(question.id)
                      ? Icons.flag
                      : Icons.outlined_flag,
                  size: 14,
                  color: _session!.flaggedQuestionIds.contains(question.id)
                      ? colors.accentAmber
                      : colors.fgSecondary,
                ),
                label: Text(
                  _session!.flaggedQuestionIds.contains(question.id)
                      ? 'Flagged'
                      : 'Flag for review',
                  style: TextStyle(
                    fontSize: 12,
                    color: _session!.flaggedQuestionIds.contains(question.id)
                        ? colors.accentAmber
                        : colors.fgSecondary,
                  ),
                ),
              ),

              // Next or Final Submit
              if (_currentIndex < totalQuestions - 1)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _currentIndex++),
                  icon: const Text('Next Question', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  label: const Icon(Icons.arrow_forward, size: 14),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentCyan,
                    foregroundColor: ThemeData.estimateBrightnessForColor(colors.accentCyan) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _handleSubmit(autoSubmit: false),
                  icon: const Icon(Icons.verified, size: 14),
                  label: const Text('Submit Final Examination', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionGeneratingPlaceholder(
    int targetIndex,
    int totalQuestions,
    AppColorsExtension colors,
  ) {
    final readyCount = _session?.questions.length ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.accentCyan, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: colors.accentCyan),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI SYNTHESIS IN PROGRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: colors.accentCyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'QUESTION ${targetIndex + 1} OF $totalQuestions',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.fgSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderSubtle, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.accentCyan.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.accentCyan.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Icon(Icons.auto_awesome, color: colors.accentCyan, size: 26),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Generating Question #${targetIndex + 1}...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.fgPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$readyCount of $totalQuestions questions prepared. AI model is synthesizing advanced scenarios without repetition.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.fgSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalQuestions > 0 ? (readyCount / totalQuestions) : null,
                        minHeight: 6,
                        backgroundColor: colors.bgElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.accentCyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (readyCount > 0)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _currentIndex = readyCount - 1),
                      icon: const Icon(Icons.arrow_back, size: 14),
                      label: Text('Jump to Available Question #$readyCount', style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.accentCyan,
                        side: BorderSide(color: colors.accentCyan.withValues(alpha: 0.5), width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _currentIndex > 0
                    ? () => setState(() => _currentIndex--)
                    : null,
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text('Previous', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.fgPrimary,
                  side: BorderSide(color: colors.borderSubtle, width: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // University Examination Blue-Book Subjective Answer Workspace
  Widget _buildSubjectiveAnswerSheet(QuestionItem question, AppColorsExtension colors) {
    final controller = _getSubjectiveController(question.id);
    final text = controller.text;
    final wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle, width: 1.0),
      ),
      child: Column(
        children: [
          // Editor Toolbar Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, size: 16, color: colors.accentAmber),
                const SizedBox(width: 8),
                Text(
                  'CANDIDATE ANSWER SHEET (BLUE-BOOK)',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                    color: colors.fgPrimary,
                  ),
                ),
                const Spacer(),
                // Helper Insert Buttons
                _buildInsertChip(
                  label: '+ Code Block',
                  onTap: () {
                    final current = controller.text;
                    final next = '$current${current.isEmpty ? '' : '\n\n'}```java\n// Write your implementation or configuration here\n\n```';
                    _lastKnownAnswers[question.id] = next;
                    controller.text = next;
                  },
                  colors: colors,
                ),
                const SizedBox(width: 6),
                _buildInsertChip(
                  label: '+ Architecture Points',
                  onTap: () {
                    final current = controller.text;
                    final next = '$current${current.isEmpty ? '' : '\n\n'}1. Architecture & Data Flow:\n2. Concurrency & Locking Strategy:\n3. Failure Recovery & Deadlocks:\n';
                    _lastKnownAnswers[question.id] = next;
                    controller.text = next;
                  },
                  colors: colors,
                ),
              ],
            ),
          ),

          // Main Multi-line Answer Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                contextMenuBuilder: (context, editableTextState) {
                  final List<ContextMenuButtonItem> buttonItems =
                      editableTextState.contextMenuButtonItems;
                  // Strip out paste action from the context menu to prevent right-click pasting
                  buttonItems.removeWhere((item) =>
                      item.type == ContextMenuButtonType.paste);
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: buttonItems,
                  );
                },
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.5,
                  color: colors.fgPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Write your university technical response, design analysis, or code implementation here...\n\nCriteria:\n• Address sub-parts clearly\n• Include code configurations where requested\n• State architectural tradeoffs and concurrency assumptions',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: colors.fgTertiary,
                    height: 1.4,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (val) {
                  final prev = _lastKnownAnswers[question.id] ?? '';
                  if (val.length - prev.length > 25) {
                    // Block unauthorized bulk paste
                    controller.text = prev;
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: prev.length),
                    );
                    _sentinel?.reportPasteViolation(
                      'Pasting external text block (${val.length - prev.length} characters) was intercepted and reverted.',
                    );
                  } else {
                    _lastKnownAnswers[question.id] = val;
                  }
                  setState(() {}); // refresh word counter
                },
              ),
            ),
          ),

          // Bottom Autosave & Word Count Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: colors.borderSubtle, width: 0.8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.accentEmerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Continuous Ledger Auto-Save Active',
                  style: TextStyle(fontSize: 10, color: colors.fgSecondary),
                ),
                const Spacer(),
                Text(
                  '$wordCount words • ${text.length} characters',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: wordCount >= 30 ? colors.accentEmerald : colors.fgSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsertChip({
    required String label,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.borderSubtle, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.accentCyan,
          ),
        ),
      ),
    );
  }

  // Objective Multiple Choice Question Cards
  Widget _buildObjectiveOptionsList(QuestionItem question, AppColorsExtension colors) {
    final selectedOptionId = _session!.userAnswers[question.id];

    return ListView.separated(
      itemCount: question.options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = selectedOptionId == option.id;
        final hotkey = '${index + 1}';

        return InkWell(
          onTap: () => _selectAnswer(question.id, option.id),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentCyan.withValues(alpha: 0.15) : colors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? colors.accentCyan : colors.borderSubtle,
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              children: [
                // Hotkey indicator pill [1], [2]
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentCyan : colors.bgElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? colors.accentCyan : colors.borderSubtle,
                      width: 0.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hotkey,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (ThemeData.estimateBrightnessForColor(colors.accentCyan) == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          : colors.fgSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Option Text
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? colors.fgPrimary : colors.fgSecondary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 18, color: colors.accentCyan),
              ],
            ),
          ),
        );
      },
    );
  }
}
