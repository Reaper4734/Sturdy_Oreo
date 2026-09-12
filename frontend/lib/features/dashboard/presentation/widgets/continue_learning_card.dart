import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_model.dart';

class ContinueLearningCard extends StatelessWidget {
  final ContinueLearningData data;
  final VoidCallback onContinue;

  const ContinueLearningCard({
    super.key,
    required this.data,
    required this.onContinue,
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
              Text('Workspace', style: TextStyle(fontSize: 13, color: colors.fgSecondary)),
              Text(data.difficulty, style: TextStyle(fontSize: 13, color: colors.fgTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(data.workspaceName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
          const SizedBox(height: 24),
          
          Text('Current Topic', style: TextStyle(fontSize: 13, color: colors.fgSecondary)),
          const SizedBox(height: 8),
          Text(data.currentTopic, style: TextStyle(fontSize: 16, color: colors.fgPrimary)),
          const SizedBox(height: 16),
          
          Text('Next Action', style: TextStyle(fontSize: 13, color: colors.fgSecondary)),
          const SizedBox(height: 8),
          Text(data.nextAction, style: TextStyle(fontSize: 16, color: colors.fgPrimary)),
          const SizedBox(height: 16),
          
          Text('Estimated Time', style: TextStyle(fontSize: 13, color: colors.fgSecondary)),
          const SizedBox(height: 8),
          Text(data.estimatedTime, style: TextStyle(fontSize: 16, color: colors.fgPrimary)),
          const SizedBox(height: 24),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Progress', style: TextStyle(fontSize: 13, color: colors.fgSecondary)),
              Text('${(data.progressPercent * 100).toInt()}%', style: TextStyle(fontSize: 13, color: colors.fgSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: data.progressPercent,
            backgroundColor: colors.bgSecondary,
            color: colors.fgAccent,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 16),

          // Continue Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: colors.fgAccent.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.fgAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Continue Learning', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
