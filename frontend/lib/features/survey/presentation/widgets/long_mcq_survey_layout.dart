import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/mastery_test_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LongMcqSurveyLayout extends ConsumerStatefulWidget {
  final List<QuestionItem> questions;
  final VoidCallback onCompleteTest;

  const LongMcqSurveyLayout({
    super.key,
    required this.questions,
    required this.onCompleteTest,
  });

  @override
  ConsumerState<LongMcqSurveyLayout> createState() => _LongMcqSurveyLayoutState();
}

class _LongMcqSurveyLayoutState extends ConsumerState<LongMcqSurveyLayout> {
  int _currentIndex = 0;
  final Map<int, String> _userAnswers = {};

  QuestionItem get _currentQuestion => widget.questions[_currentIndex];

  void _handleOptionSelect(String optionId) {
    setState(() {
      _userAnswers[_currentIndex] = optionId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final question = _currentQuestion;
    final selectedOptionId = _userAnswers[_currentIndex];

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
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
                Icon(Icons.assignment_outlined, size: 16, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Text(
                  'Comprehensive Mastery Assessment · Question ${_currentIndex + 1} of ${widget.questions.length}',
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

          // Question Content & Options
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

                    // Options Grid
                    ...question.options.map((opt) {
                      final isSelected = selectedOptionId == opt.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _handleOptionSelect(opt.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.accentPrimary.withValues(alpha: 0.12) : colors.bgCanvas,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: isSelected ? colors.accentPrimary : colors.fgSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    opt.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: colors.fgPrimary,
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
            ),
          ),

          // Footer Bar with Previous/Next/Submit Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: colors.bgActivityBar,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(top: BorderSide(color: colors.borderSubtle)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                  icon: const Icon(Icons.chevron_left_rounded, size: 16),
                  label: const Text('Previous', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.fgPrimary,
                    side: BorderSide(color: colors.borderSubtle),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _currentIndex + 1 < widget.questions.length ? () => setState(() => _currentIndex++) : null,
                  icon: const Icon(Icons.chevron_right_rounded, size: 16),
                  label: const Text('Next', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.fgPrimary,
                    side: BorderSide(color: colors.borderSubtle),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => widget.onCompleteTest(),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Submit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
