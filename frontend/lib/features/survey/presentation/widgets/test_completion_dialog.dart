import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/mastery_test_model.dart';

class TestCompletionDialog extends StatelessWidget {
  final TestResultSummary summary;
  final VoidCallback onReturnToDashboard;

  const TestCompletionDialog({
    super.key,
    required this.summary,
    required this.onReturnToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accentEmerald, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration Icon Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentEmerald.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentEmerald, width: 2),
              ),
              child: const Icon(
                Icons.stars_rounded,
                size: 38,
                color: AppColors.accentEmerald,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Mastery Checkpoint Completed!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.fgPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your cognitive retention data has been synced to your DAG track.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.fgSecondary),
            ),
            const SizedBox(height: 20),

            // Telemetry Cards Row
            Row(
              children: [
                _buildStatTile('Score', '${summary.scorePercent.toInt()}%', AppColors.accentEmerald),
                const SizedBox(width: 8),
                _buildStatTile('Accuracy', '${summary.correctAnswers}/${summary.totalQuestions}', AppColors.accentPrimary),
                const SizedBox(width: 8),
                _buildStatTile('XP Earned', '+${summary.xpEarned}', const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 16),

            // Spaced Repetition Schedule Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCanvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: AppColors.accentEmerald),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Next Spaced Repetition Review: ${summary.recommendedIntervalDays} days',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CTAs
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.fgPrimary,
                      side: const BorderSide(color: AppColors.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Review Answers', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onReturnToDashboard();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Command Center →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.fgSecondary)),
          ],
        ),
      ),
    );
  }
}
