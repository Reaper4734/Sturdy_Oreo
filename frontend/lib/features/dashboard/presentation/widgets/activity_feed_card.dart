import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_model.dart';

class ActivityFeedCard extends StatelessWidget {
  final List<TimelineEvent> events;

  const ActivityFeedCard({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final displayEvents = events.take(5).toList();
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
          Text('Activity Feed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
          const SizedBox(height: 32),
          
          Column(
            children: displayEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == displayEvents.length - 1;
              return _buildFeedItem(context, event, isLast);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(BuildContext context, TimelineEvent event, bool isLast) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline visual
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.fgAccent,
          ),
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.relativeTime,
                  style: TextStyle(fontSize: 13, color: colors.fgSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(fontSize: 16, color: colors.fgPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (event.optionalXp != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.accentWarning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${event.optionalXp} XP',
                          style: TextStyle(fontSize: 12, color: colors.accentWarning, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
