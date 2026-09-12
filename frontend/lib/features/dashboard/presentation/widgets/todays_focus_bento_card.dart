import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import 'dashboard_illustrations.dart';

class TodaysFocusBentoCard extends StatelessWidget {
  final String focusTopic;
  final int estimatedMinutes;
  final double sessionProgress;
  final List<String> focusTags;
  final VoidCallback onStartSession;

  const TodaysFocusBentoCard({
    super.key,
    required this.focusTopic,
    this.estimatedMinutes = 35,
    this.sessionProgress = 0.5,
    this.focusTags = const [],
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayTopic = focusTopic.isNotEmpty ? focusTopic : 'Daily Session Goal';
    final pct = (sessionProgress * 100).toInt().clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Title + Daily Mission Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  size: 16,
                  color: Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Today's Focus",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.fgPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 10)),
                    SizedBox(width: 4),
                    Text(
                      'Daily Mission',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Body: Details on left, Bullseye Illustration on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Complete today's session",
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.fgSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayTopic,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.fgPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Time info
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 13, color: colors.fgSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$estimatedMinutes min',
                          style: TextStyle(fontSize: 11, color: colors.fgSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Orange Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: sessionProgress > 0 ? sessionProgress.clamp(0.0, 1.0) : 0.1,
                              minHeight: 6,
                              backgroundColor: colors.borderSubtle,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.fgPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Right Vector Bullseye
              const TargetBullseyeIllustration(size: 95),
            ],
          ),

          const SizedBox(height: 16),

          // Focus Tags Pill + Action Button
          Row(
            children: [
              // Focus Tags
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.bgActivityBar,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF97316),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          focusTags.isNotEmpty
                              ? 'Focus: ${focusTags.take(3).join(', ')}'
                              : 'Focus: Core concepts and applied problems',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.fgSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Amber CTA Button
              ElevatedButton.icon(
                onPressed: onStartSession,
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Start Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316), // Solid Amber/Orange CTA
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
