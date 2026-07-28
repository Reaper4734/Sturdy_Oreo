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
              const Text('Workspace', style: TextStyle(fontSize: 13, color: AppColors.fgSecondary)),
              Text(data.difficulty, style: const TextStyle(fontSize: 13, color: AppColors.fgTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(data.workspaceName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
          const SizedBox(height: 24),
          
          const Text('Current Topic', style: TextStyle(fontSize: 13, color: AppColors.fgSecondary)),
          const SizedBox(height: 8),
          Text(data.currentTopic, style: const TextStyle(fontSize: 16, color: AppColors.fgPrimary)),
          const SizedBox(height: 16),
          
          const Text('Next Action', style: TextStyle(fontSize: 13, color: AppColors.fgSecondary)),
          const SizedBox(height: 8),
          Text(data.nextAction, style: const TextStyle(fontSize: 16, color: AppColors.fgPrimary)),
          const SizedBox(height: 16),
          
          const Text('Estimated Time', style: TextStyle(fontSize: 13, color: AppColors.fgSecondary)),
          const SizedBox(height: 8),
          Text(data.estimatedTime, style: const TextStyle(fontSize: 16, color: AppColors.fgPrimary)),
          const SizedBox(height: 24),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Progress', style: TextStyle(fontSize: 13, color: AppColors.fgSecondary)),
              Text('${(data.progressPercent * 100).toInt()}%', style: const TextStyle(fontSize: 13, color: AppColors.fgSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: data.progressPercent,
            backgroundColor: AppColors.bgSecondary,
            color: AppColors.fgAccent,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 32),
          const Spacer(),

          // Continue Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.fgAccent.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.fgAccent,
                foregroundColor: AppColors.bgCanvas,
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
