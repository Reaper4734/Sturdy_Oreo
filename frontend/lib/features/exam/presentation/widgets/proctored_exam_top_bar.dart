import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class ProctoredExamTopBar extends StatelessWidget {
  final String courseTitle;
  final int remainingSeconds;
  final double trustScore;
  final int strikeCount;
  final VoidCallback onSubmit;

  const ProctoredExamTopBar({
    super.key,
    required this.courseTitle,
    required this.remainingSeconds,
    required this.trustScore,
    required this.strikeCount,
    required this.onSubmit,
  });

  String get _formattedTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLowTime = remainingSeconds < 180;
    final isCriticalTime = remainingSeconds < 60;

    final trustColor = trustScore >= 85
        ? colors.accentEmerald
        : (trustScore >= 60 ? colors.accentAmber : colors.accentRose);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgActivityBar,
        border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          // 1. Proctored Exam Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined, size: 14, color: colors.accentPrimary),
                const SizedBox(width: 6),
                Text(
                  'PROCTORED EXAM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: colors.accentPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 2. Course Title
          Flexible(
            child: Text(
              courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.fgPrimary),
            ),
          ),

          const SizedBox(width: 16),

          // 3. Live Countdown Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCriticalTime
                  ? colors.accentRose.withValues(alpha: 0.2)
                  : (isLowTime
                      ? colors.accentAmber.withValues(alpha: 0.15)
                      : colors.bgElevated),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCriticalTime
                    ? colors.accentRose
                    : (isLowTime ? colors.accentAmber : colors.borderSubtle),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: isCriticalTime
                      ? colors.accentRose
                      : (isLowTime ? colors.accentAmber : colors.fgSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  _formattedTime,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: isCriticalTime
                        ? colors.accentRose
                        : (isLowTime ? colors.accentAmber : colors.fgPrimary),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 4. Trust Score Pill
          Tooltip(
            message: 'Academic Integrity Trust Score (Decreases on tab switches / focus loss)',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: trustColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: trustColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: trustColor),
                  const SizedBox(width: 6),
                  Text(
                    '${trustScore.toStringAsFixed(0)}% Trust',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: trustColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 5. Strike Counter Nodes
          Tooltip(
            message: 'Strikes ($strikeCount/3): 3 infractions results in automatic lockout',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final isInfracted = index < strikeCount;
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: isInfracted ? colors.accentRose : colors.borderSubtle,
                    shape: BoxShape.circle,
                    boxShadow: isInfracted
                        ? [
                            BoxShadow(
                              color: colors.accentRose.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 14),

          // 6. Submit Button
          ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.send_rounded, size: 14),
            label: const Text('Submit Exam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentEmerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
