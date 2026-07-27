import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/mock_dashboard_data.dart';

class LearningJourneyCard extends StatelessWidget {
  final LearningJourneyData data;

  const LearningJourneyCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final progressPct = (data.overallProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Learning Journey', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: JourneyMetricCard(value: '$progressPct%', label: 'Progress')),
              const SizedBox(width: 16),
              Expanded(child: JourneyMetricCard(value: '${data.level}', label: 'Level')),
              const SizedBox(width: 16),
              Expanded(child: JourneyMetricCard(value: '${data.xp}', label: 'XP')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: JourneyMetricCard(value: '${data.streakDays}', label: 'Day Streak')),
              const SizedBox(width: 16),
              Expanded(child: JourneyMetricCard(value: '${data.hoursLearned.round()}h', label: 'Learned')),
              const SizedBox(width: 16),
              Expanded(child: JourneyMetricCard(value: '${data.hoursRemaining.round()}h', label: 'Remaining')),
            ],
          ),
        ],
      ),
    );
  }
}

class JourneyMetricCard extends StatelessWidget {
  final String value;
  final String label;

  const JourneyMetricCard({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.fgSecondary)),
        ],
      ),
    );
  }
}
