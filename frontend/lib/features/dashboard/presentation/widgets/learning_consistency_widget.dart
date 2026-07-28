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
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Learning Consistency', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
              Row(
                children: [
                  _buildStat('Current Streak', '${summary.longestStreak} Days'), // Normally would be current streak, mocking with longest
                  const SizedBox(width: 32),
                  _buildStat('Best Streak', '${summary.longestStreak} Days'),
                  const SizedBox(width: 32),
                  _buildStat('Consistency', '${summary.weeklyConsistency}%'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          LayoutBuilder(
            builder: (context, constraints) {
              // Automatically calculate based on available width
              final availableWidth = constraints.maxWidth;
              const int targetRows = 7;
              const int totalDays = 365;
              final int columns = (totalDays / targetRows).ceil(); // ~53
              
              // We want spacing to be roughly 10% of cell size, up to 4px
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
                    
                    // Simple mock data for tooltip
                    final date = DateTime.now().subtract(Duration(days: 364 - index));
                    final dateStr = DateFormat('d MMM').format(date);
                    
                    String tooltipMsg = '$dateStr\nNo Activity';
                    if (score > 0) {
                      tooltipMsg = '$dateStr\n${(score * 0.05).toStringAsFixed(1)} Hours\n+${(score * 2.5).round()} XP';
                    }

                    return Tooltip(
                      message: tooltipMsg,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      textStyle: const TextStyle(fontSize: 13, color: AppColors.fgPrimary, fontWeight: FontWeight.normal, height: 1.5),
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getColorForScore(score),
                          borderRadius: BorderRadius.circular(cellSize * 0.2), // slightly rounded
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

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.fgSecondary)),
      ],
    );
  }

  Color _getColorForScore(int score) {
    if (score == 0) return AppColors.bgSecondary;
    if (score < 25) return AppColors.fgAccent.withValues(alpha: 0.2);
    if (score < 50) return AppColors.fgAccent.withValues(alpha: 0.5);
    if (score < 75) return AppColors.fgAccent.withValues(alpha: 0.8);
    return AppColors.fgAccent;
  }
}
