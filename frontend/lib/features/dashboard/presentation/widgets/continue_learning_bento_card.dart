import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import 'dashboard_illustrations.dart';

class ContinueLearningBentoCard extends StatelessWidget {
  final String subject;
  final String currentTopic;
  final double progressPercent;
  final int completedNodes;
  final int totalNodes;
  final int estimatedMinutesRemaining;
  final VoidCallback onContinue;

  const ContinueLearningBentoCard({
    super.key,
    required this.subject,
    required this.currentTopic,
    this.progressPercent = 0.0,
    this.completedNodes = 0,
    this.totalNodes = 0,
    this.estimatedMinutesRemaining = 25,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displaySubject = subject.isNotEmpty ? subject : 'Active Subject';
    final displayTopic = currentTopic.isNotEmpty ? currentTopic : 'Core Fundamentals';
    final pct = (progressPercent * 100).toInt().clamp(0, 100);

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
          // Header Row: Icon + Title + 3-dots menu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Continue Learning',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.fgPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: colors.fgSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Body: Details on left, Illustration on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DEEP DIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subject Title
                    Text(
                      displaySubject,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.fgPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Active Topic / Subtitle
                    Text(
                      displayTopic,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.fgSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Progress Bar + Percentage Text
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressPercent.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: colors.borderSubtle,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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

              const SizedBox(width: 16),

              // Right Vector Graphic
              const StudyStackIllustration(size: 110),
            ],
          ),

          const SizedBox(height: 18),
          Divider(color: colors.borderSubtle, height: 1.0, thickness: 1.0),
          const SizedBox(height: 14),

          // Bottom Action & Meta Row
          Row(
            children: [
              // Estimated Time
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: colors.fgSecondary),
                  const SizedBox(width: 5),
                  Text(
                    '$estimatedMinutesRemaining min left',
                    style: TextStyle(fontSize: 11, color: colors.fgSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Concepts Count
              if (totalNodes > 0) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hub_outlined, size: 14, color: colors.fgSecondary),
                    const SizedBox(width: 5),
                    Text(
                      '$completedNodes / $totalNodes concepts mastered',
                      style: TextStyle(fontSize: 11, color: colors.fgSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Primary Action Button (Blue)
              ElevatedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // Solid Blue CTA
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
