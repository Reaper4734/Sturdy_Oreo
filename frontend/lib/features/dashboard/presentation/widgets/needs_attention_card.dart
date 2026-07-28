import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_model.dart';

class NeedsAttentionCard extends StatelessWidget {
  final List<AttentionItem> items;

  const NeedsAttentionCard({super.key, required this.items});

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
          const Text('Needs Attention', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
          const SizedBox(height: 32),
          if (items.isEmpty)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nothing requires your attention.', style: TextStyle(fontSize: 16, color: AppColors.fgPrimary)),
                SizedBox(height: 8),
                Text('You\'re ready to continue learning.', style: TextStyle(fontSize: 14, color: AppColors.fgSecondary)),
              ],
            )
          else
            ...items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildItemCard(item),
            )),
        ],
      ),
    );
  }

  Widget _buildItemCard(AttentionItem item) {
    final Color iconColor;
    final IconData icon;

    switch (item.type) {
      case AttentionType.pendingQuiz:
        iconColor = AppColors.accentWarning;
        icon = Icons.quiz_outlined;
      case AttentionType.resumeProject:
        iconColor = AppColors.fgAccent;
        icon = Icons.code;
      case AttentionType.reviewSuggested:
        iconColor = AppColors.fgSecondary;
        icon = Icons.history_edu;
      case AttentionType.remedialLesson:
        iconColor = AppColors.accentDestructive;
        icon = Icons.warning_amber_rounded;
    }

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
              const SizedBox(height: 4),
              Text(item.subtitle, style: const TextStyle(fontSize: 14, color: AppColors.fgSecondary)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.fgTertiary, size: 24),
      ],
    );
  }
}
