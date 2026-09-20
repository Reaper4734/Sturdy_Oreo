import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/mastery_test_model.dart';

class ExamQuestionMatrix extends StatelessWidget {
  final List<QuestionItem> questions;
  final int totalTargetQuestions;
  final bool isGenerating;
  final int currentIndex;
  final Map<String, String> userAnswers;
  final Set<String> flaggedQuestionIds;
  final ValueChanged<int> onSelectQuestion;
  final ValueChanged<String> onToggleFlag;

  const ExamQuestionMatrix({
    super.key,
    required this.questions,
    this.totalTargetQuestions = 5,
    this.isGenerating = false,
    required this.currentIndex,
    required this.userAnswers,
    required this.flaggedQuestionIds,
    required this.onSelectQuestion,
    required this.onToggleFlag,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalCount = totalTargetQuestions > 0 ? totalTargetQuestions : questions.length;
    final readyCount = questions.length;
    final answeredCount = userAnswers.values.where((ans) => ans.trim().isNotEmpty).length;
    final currentQ = questions.isNotEmpty && currentIndex < questions.length ? questions[currentIndex] : null;
    final isCurrentFlagged = currentQ != null && flaggedQuestionIds.contains(currentQ.id);

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSidebar,
        border: Border(left: BorderSide(color: colors.borderSubtle, width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QUESTION NAVIGATOR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: colors.fgSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderSubtle, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isGenerating && readyCount < totalCount) ...[
                            SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(strokeWidth: 1.2, color: colors.accentCyan),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            '$answeredCount / $totalCount',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.accentEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Current Question Flag Toggle
                if (currentQ != null)
                  InkWell(
                    onTap: () => onToggleFlag(currentQ.id),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isCurrentFlagged ? colors.warningSubtle : colors.bgSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCurrentFlagged ? colors.accentAmber : colors.borderSubtle,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCurrentFlagged ? Icons.flag : Icons.outlined_flag,
                            size: 14,
                            color: isCurrentFlagged ? colors.accentAmber : colors.fgSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isCurrentFlagged ? 'Flagged for Review' : 'Flag Question ${currentIndex + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isCurrentFlagged ? colors.accentAmber : colors.fgPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.8),

          // Question Matrix Grid
          Expanded(
            child: totalCount == 0
                ? Center(
                    child: Text(
                      'No questions available',
                      style: TextStyle(fontSize: 12, color: colors.fgSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      final isReady = index < questions.length;
                      final isCurrent = index == currentIndex;

                      if (!isReady) {
                        // Pending / Background Generating Tile
                        return InkWell(
                          onTap: () => onSelectQuestion(index),
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isCurrent ? colors.accentCyan.withValues(alpha: 0.1) : colors.bgBase,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent ? colors.accentCyan : colors.borderSubtle.withValues(alpha: 0.5),
                                width: isCurrent ? 1.5 : 0.8,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrent ? colors.accentCyan : colors.fgTertiary,
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 8,
                                    color: isCurrent ? colors.accentCyan : colors.fgTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final q = questions[index];
                      final isAnswered = (userAnswers[q.id]?.trim().isNotEmpty ?? false);
                      final isFlagged = flaggedQuestionIds.contains(q.id);

                      Color bg = colors.bgSurface;
                      Color border = colors.borderSubtle;
                      Color text = colors.fgSecondary;

                      if (isCurrent) {
                        bg = colors.accentCyan.withValues(alpha: 0.15);
                        border = colors.accentCyan;
                        text = colors.accentCyan;
                      } else if (isAnswered) {
                        bg = colors.successSubtle;
                        border = colors.successBorder;
                        text = colors.accentEmerald;
                      }

                      return InkWell(
                        onTap: () => onSelectQuestion(index),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: border,
                              width: isCurrent ? 1.5 : 0.8,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  color: text,
                                ),
                              ),
                              if (isFlagged)
                                Positioned(
                                  top: 3,
                                  right: 3,
                                  child: Icon(
                                    Icons.flag,
                                    size: 9,
                                    color: colors.accentAmber,
                                  ),
                                ),
                              if (isAnswered && !isCurrent)
                                Positioned(
                                  bottom: 3,
                                  right: 3,
                                  child: Icon(
                                    Icons.check,
                                    size: 9,
                                    color: colors.accentEmerald,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              border: Border(top: BorderSide(color: colors.borderSubtle, width: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(colors.accentCyan, 'Current Question', colors),
                const SizedBox(height: 4),
                _buildLegendItem(colors.accentEmerald, 'Answered', colors),
                const SizedBox(height: 4),
                _buildLegendItem(colors.accentAmber, 'Flagged for review', colors),
                const SizedBox(height: 4),
                _buildLegendItem(colors.fgSecondary, 'Unanswered', colors),
                if (isGenerating) ...[
                  const SizedBox(height: 4),
                  _buildLegendItem(colors.fgTertiary, 'AI Synthesizing...', colors),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color dotColor, String label, AppColorsExtension colors) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.fgSecondary),
        ),
      ],
    );
  }
}
