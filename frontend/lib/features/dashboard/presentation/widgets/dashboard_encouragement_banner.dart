import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class DashboardEncouragementBanner extends StatelessWidget {
  final String learnerName;

  const DashboardEncouragementBanner({
    super.key,
    required this.learnerName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = learnerName.isNotEmpty ? learnerName : 'Learner';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          // Rocket container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🚀', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 14),

          // Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "You're doing great! Keep going, $name.",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.fgPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Every concept you learn today builds your tomorrow.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.fgSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Right Sparkline / Growth Graphic
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              size: 20,
              color: Color(0xFF38BDF8),
            ),
          ),
        ],
      ),
    );
  }
}
