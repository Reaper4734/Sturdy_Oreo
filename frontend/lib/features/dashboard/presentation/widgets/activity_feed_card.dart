import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/mock_dashboard_data.dart';

class ActivityFeedCard extends StatelessWidget {
  final List<TimelineEvent> events;

  const ActivityFeedCard({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final displayEvents = events.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Activity Feed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
          const SizedBox(height: 32),
          
          Column(
            children: displayEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == displayEvents.length - 1;
              return _buildFeedItem(event, isLast);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(TimelineEvent event, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline visual
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.fgAccent,
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
                    style: const TextStyle(fontSize: 13, color: AppColors.fgSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(fontSize: 16, color: AppColors.fgPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (event.optionalXp != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentWarning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${event.optionalXp} XP',
                            style: const TextStyle(fontSize: 12, color: AppColors.accentWarning, fontWeight: FontWeight.bold),
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
