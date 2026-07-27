import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/mastery_test_model.dart';

class PopupQuestionnaireLayout extends StatefulWidget {
  final List<QuestionItem> questions;
  final VoidCallback onCompleteTest;
  final VoidCallback? onClose;

  const PopupQuestionnaireLayout({
    super.key,
    required this.questions,
    required this.onCompleteTest,
    this.onClose,
  });

  @override
  State<PopupQuestionnaireLayout> createState() => _PopupQuestionnaireLayoutState();
}

class _PopupQuestionnaireLayoutState extends State<PopupQuestionnaireLayout> {
  int _currentIndex = 0;
  String? _selectedOptionId;
  bool _hasSubmittedCurrent = false;
  int _correctCount = 0;

  QuestionItem get _currentQuestion => widget.questions[_currentIndex];

  void _handleSubmit() {
    if (_selectedOptionId == null) return;

    final selectedOpt = _currentQuestion.options.firstWhere((o) => o.id == _selectedOptionId);
    if (!_hasSubmittedCurrent) {
      setState(() {
        _hasSubmittedCurrent = true;
        if (selectedOpt.isCorrect) {
          _correctCount++;
        }
      });
    } else {
      // Move to next question or complete test directly (returning to Learning Lab)
      if (_currentIndex + 1 < widget.questions.length) {
        setState(() {
          _currentIndex++;
          _selectedOptionId = null;
          _hasSubmittedCurrent = false;
        });
      } else {
        widget.onCompleteTest();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;

    return Center(
      child: Container(
        width: 580,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.bgActivityBar,
                child: Row(
                  children: [
                    const Icon(Icons.quiz_outlined, size: 16, color: AppColors.accentEmerald),
                    const SizedBox(width: 8),
                    Text(
                      'Micro-Quiz Checkpoint · Score: $_correctCount/${_currentIndex + 1} · Q${_currentIndex + 1}/${widget.questions.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        question.topicTag,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentEmerald),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: widget.onClose ?? widget.onCompleteTest,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.fgSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Question Body ---
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.questionText,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.fgPrimary, height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    // Options List
                    ...question.options.map((opt) {
                      final isSelected = _selectedOptionId == opt.id;
                      Color borderColor = AppColors.borderSubtle;
                      Color bgColor = AppColors.bgCanvas;

                      if (_hasSubmittedCurrent) {
                        if (opt.isCorrect) {
                          borderColor = AppColors.accentEmerald;
                          bgColor = AppColors.accentEmerald.withValues(alpha: 0.12);
                        } else if (isSelected && !opt.isCorrect) {
                          borderColor = Colors.orange;
                          bgColor = Colors.orange.withValues(alpha: 0.12);
                        }
                      } else if (isSelected) {
                        borderColor = AppColors.accentPrimary;
                        bgColor = AppColors.accentPrimary.withValues(alpha: 0.12);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: _hasSubmittedCurrent ? null : () => setState(() => _selectedOptionId = opt.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _hasSubmittedCurrent
                                      ? (opt.isCorrect
                                          ? Icons.check_circle_rounded
                                          : (isSelected ? Icons.cancel_rounded : Icons.radio_button_unchecked))
                                      : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                                  size: 16,
                                  color: _hasSubmittedCurrent
                                      ? (opt.isCorrect ? AppColors.accentEmerald : (isSelected ? Colors.orange : AppColors.fgSecondary))
                                      : (isSelected ? AppColors.accentPrimary : AppColors.fgSecondary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    opt.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: AppColors.fgPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // --- Footer Bar (Bottom Right Submit Button as in Wireframe 1) ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.bgActivityBar,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected: ${_selectedOptionId != null ? "1 Answer" : "None"}',
                      style: const TextStyle(fontSize: 11, color: AppColors.fgSecondary),
                    ),
                    ElevatedButton(
                      onPressed: _selectedOptionId == null ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        _hasSubmittedCurrent
                            ? (_currentIndex + 1 < widget.questions.length ? 'Next Question →' : 'View Results')
                            : 'Submit Answer',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
