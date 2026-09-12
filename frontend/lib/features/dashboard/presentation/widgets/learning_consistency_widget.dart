import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_model.dart';
import 'package:intl/intl.dart';

class LearningConsistencyWidget extends StatelessWidget {
  final List<int> scores;
  final HeatmapSummary summary;

  const LearningConsistencyWidget({
    super.key,
    required this.scores,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: AppSpacing.pXl,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: AppRadius.rXl,
        border: Border.all(color: colors.borderSubtle, width: 1),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Learning Consistency', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
              Row(
                children: [
                  _buildStat(context, 'Current Streak', '${summary.longestStreak} Days'),
                  const SizedBox(width: 32),
                  _buildStat(context, 'Best Streak', '${summary.longestStreak} Days'),
                  const SizedBox(width: 32),
                  _buildStat(context, 'Consistency', '${summary.weeklyConsistency}%'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              const int targetRows = 7;
              const int totalDays = 365;
              final int columns = (totalDays / targetRows).ceil(); // ~53
              
              final double maxSpacing = 4.0;
              final double calculatedSpacing = (availableWidth * 0.05 / columns).clamp(1.0, maxSpacing);
              final double cellSize = (availableWidth - (columns - 1) * calculatedSpacing) / columns;
              
              return SizedBox(
                width: availableWidth,
                height: (cellSize * targetRows) + (calculatedSpacing * (targetRows - 1)),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: calculatedSpacing,
                    crossAxisSpacing: calculatedSpacing,
                  ),
                  itemCount: scores.length,
                  itemBuilder: (context, index) {
                    final score = scores[index];
                    
                    final date = DateTime.now().subtract(Duration(days: 364 - index));
                    final dateStr = DateFormat('d MMM').format(date);
                    
                    String tooltipMsg = '$dateStr\nNo Activity';
                    if (score > 0) {
                      tooltipMsg = '$dateStr\n${(score * 0.05).toStringAsFixed(1)} Hours\n+${(score * 2.5).round()} XP';
                    }

                    return Tooltip(
                      message: tooltipMsg,
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      textStyle: TextStyle(fontSize: 13, color: colors.fgPrimary, fontWeight: FontWeight.normal, height: 1.5),
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getColorForScore(context, score),
                          borderRadius: BorderRadius.circular(cellSize * 0.2),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: colors.fgSecondary)),
      ],
    );
  }

  Color _getColorForScore(BuildContext context, int score) {
    final colors = context.colors;
    if (score == 0) return colors.bgSecondary;
    if (score < 25) return colors.fgAccent.withValues(alpha: 0.2);
    if (score < 50) return colors.fgAccent.withValues(alpha: 0.5);
    if (score < 75) return colors.fgAccent.withValues(alpha: 0.8);
    return colors.fgAccent;
  }
}
