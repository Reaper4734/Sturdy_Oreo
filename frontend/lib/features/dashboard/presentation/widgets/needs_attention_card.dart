import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_model.dart';

class NeedsAttentionCard extends StatelessWidget {
  final List<AttentionItem> items;

  const NeedsAttentionCard({super.key, required this.items});

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
          Text('Needs Attention', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
          const SizedBox(height: 32),
          if (items.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nothing requires your attention.', style: TextStyle(fontSize: 16, color: colors.fgPrimary)),
                const SizedBox(height: 8),
                Text('You\'re ready to continue learning.', style: TextStyle(fontSize: 14, color: colors.fgSecondary)),
              ],
            )
          else
            ...items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildItemCard(context, item),
            )),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, AttentionItem item) {
    final colors = context.colors;
    final Color iconColor;
    final IconData icon;

    switch (item.type) {
      case AttentionType.pendingQuiz:
        iconColor = colors.accentWarning;
        icon = Icons.quiz_outlined;
      case AttentionType.resumeProject:
        iconColor = colors.fgAccent;
        icon = Icons.code;
      case AttentionType.reviewSuggested:
        iconColor = colors.fgSecondary;
        icon = Icons.history_edu;
      case AttentionType.remedialLesson:
        iconColor = colors.accentDestructive;
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
              Text(item.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
              const SizedBox(height: 4),
              Text(item.subtitle, style: TextStyle(fontSize: 14, color: colors.fgSecondary)),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: colors.fgTertiary, size: 24),
      ],
    );
  }
}
