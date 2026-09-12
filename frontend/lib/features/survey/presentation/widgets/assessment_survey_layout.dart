import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/mastery_test_model.dart';
import '../../../../shared/providers/workspace_providers.dart';
import '../../data/http_assessment_repository.dart';

class AssessmentSurveyLayout extends ConsumerStatefulWidget {
  final List<QuestionItem> questions;
  final VoidCallback onCompleteTest;

  const AssessmentSurveyLayout({
    super.key,
    required this.questions,
    required this.onCompleteTest,
  });

  @override
  ConsumerState<AssessmentSurveyLayout> createState() => _AssessmentSurveyLayoutState();
}

class _AssessmentSurveyLayoutState extends ConsumerState<AssessmentSurveyLayout> {
  int _currentIndex = 0;
  final Map<int, String> _userAnswers = {}; // Store selected option ID for MCQ, or text for subjective
  final TextEditingController _textController = TextEditingController();
  
  bool _isEvaluating = false;
  Map<String, dynamic>? _evaluationResult;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  QuestionItem get _currentQuestion => widget.questions[_currentIndex];

  void _handleOptionSelect(String optionId) {
    setState(() {
      _userAnswers[_currentIndex] = optionId;
    });
  }

  Future<void> _submitSubjectiveAnswer(String answerText) async {
    setState(() {
      _isEvaluating = true;
      _evaluationResult = null;
    });
    
    try {
      final repo = ref.read(httpAssessmentRepositoryProvider);
      final activeWs = ref.read(activeWorkspaceProvider);
      final topic = activeWs?.activeLearningContext ?? 'General Topic';
      
      final result = await repo.evaluateAnswer(topic, _currentQuestion.questionText, answerText);
      
      setState(() {
        _evaluationResult = result;
        _isEvaluating = false;
        _userAnswers[_currentIndex] = answerText; // mark as answered
      });
    } catch (e) {
      debugPrint("Failed to evaluate: $e");
      setState(() {
        _isEvaluating = false;
      });
    }
  }

  void _handleNext() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _evaluationResult = null;
      });
    } else {
      widget.onCompleteTest();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (widget.questions.isEmpty) {
      return Center(child: Text("No questions generated.", style: TextStyle(color: colors.fgPrimary)));
    }

    final question = _currentQuestion;
    final isSubjective = question.type == QuestionType.subjective;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.bgActivityBar,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: colors.borderSubtle)),
            ),
            child: Row(
              children: [
                Icon(isSubjective ? Icons.edit_note_rounded : Icons.fact_check_outlined, size: 16, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Text(
                  'Dynamic Assessment · Question ${_currentIndex + 1} of ${widget.questions.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    question.topicTag,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.accentPrimary),
                  ),
                ),
              ],
            ),
          ),

          // Question Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.questionText,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.fgPrimary, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    if (isSubjective)
                      _buildSubjectiveArea(context)
                    else
                      _buildMcqArea(context, question),
                      
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: colors.bgActivityBar,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(top: BorderSide(color: colors.borderSubtle)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentIndex > 0 ? () => setState(() { _currentIndex--; _evaluationResult = null; }) : null,
                  style: TextButton.styleFrom(foregroundColor: colors.fgSecondary),
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: (_userAnswers.containsKey(_currentIndex) || _evaluationResult != null) ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.fgInverse,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_currentIndex == widget.questions.length - 1 ? 'Finish Assessment' : 'Next Question'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMcqArea(BuildContext context, QuestionItem question) {
    final colors = context.colors;
    final selectedOptionId = _userAnswers[_currentIndex];
    
    return Column(
      children: question.options.map((opt) {
        final isSelected = selectedOptionId == opt.id;
        final showAnswer = selectedOptionId != null;
        
        Color borderColor = colors.borderSubtle;
        if (showAnswer) {
          if (opt.isCorrect) {
            borderColor = colors.accentEmerald;
          } else if (isSelected && !opt.isCorrect) {
            borderColor = colors.accentRose;
          }
        } else if (isSelected) {
          borderColor = colors.accentPrimary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: showAnswer ? null : () => _handleOptionSelect(opt.id),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colors.accentPrimary : colors.fgSecondary,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: colors.accentPrimary, shape: BoxShape.circle)))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opt.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? colors.fgPrimary : colors.fgSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (showAnswer && opt.isCorrect)
                    Icon(Icons.check_circle_rounded, color: colors.accentEmerald, size: 20),
                  if (showAnswer && isSelected && !opt.isCorrect)
                    Icon(Icons.cancel_rounded, color: colors.accentRose, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectiveArea(BuildContext context) {
    final colors = context.colors;
    if (_evaluationResult != null) {
      final isPassed = _evaluationResult!['isPassed'] == true;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPassed ? colors.accentEmerald.withValues(alpha: 0.1) : colors.accentRose.withValues(alpha: 0.1),
          border: Border.all(color: isPassed ? colors.accentEmerald : colors.accentRose),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isPassed ? Icons.check_circle : Icons.warning_amber_rounded, color: isPassed ? colors.accentEmerald : colors.accentRose),
                const SizedBox(width: 8),
                Text(isPassed ? 'Passed! Score: ${_evaluationResult!['score']}' : 'Needs Work! Score: ${_evaluationResult!['score']}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isPassed ? colors.accentEmerald : colors.accentRose, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Feedback: ${_evaluationResult!['feedback']}', style: TextStyle(color: colors.fgPrimary)),
            if (!isPassed && _evaluationResult!['suggestedReviewTopic'] != null && _evaluationResult!['suggestedReviewTopic'].toString().isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Text('Suggested Review: ${_evaluationResult!['suggestedReviewTopic']}', style: TextStyle(color: colors.accentAmber)),
               ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          maxLines: 5,
          onSubmitted: (val) => _submitSubjectiveAnswer(val),
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            border: const OutlineInputBorder(),
            fillColor: colors.bgCanvas,
            filled: true,
          ),
          style: TextStyle(color: colors.fgPrimary),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        if (_isEvaluating)
          Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary)),
              const SizedBox(width: 8),
              Text('AI is evaluating your answer...', style: TextStyle(color: colors.fgSecondary)),
            ],
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_textController.text.trim().isNotEmpty) {
                  _submitSubjectiveAnswer(_textController.text.trim());
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Submit Answer'),
            ),
          )
      ],
    );
  }
}
