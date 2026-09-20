import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../models/proctored_exam_model.dart';

class ViolationWarningDialog extends StatelessWidget {
  final ExamViolation? violation;
  final int strikeCount;
  final bool isDisqualified;
  final VoidCallback onDismiss;

  const ViolationWarningDialog({
    super.key,
    this.violation,
    required this.strikeCount,
    this.isDisqualified = false,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    ExamViolation? violation,
    required int strikeCount,
    bool isDisqualified = false,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: ViolationWarningDialog(
          violation: violation,
          strikeCount: strikeCount,
          isDisqualified: isDisqualified,
          onDismiss: () {
            Navigator.of(ctx).pop();
            onDismiss();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCritical = isDisqualified || strikeCount >= 3;
    final themeColor = isCritical ? colors.accentRose : colors.accentAmber;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.bgModal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Pill
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: themeColor.withValues(alpha: 0.4)),
              ),
              child: Icon(
                isCritical ? Icons.gpp_bad_rounded : Icons.warning_amber_rounded,
                color: themeColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Text(
              isCritical
                  ? 'EXAM SESSION DISQUALIFIED'
                  : 'INTEGRITY ALERT — STRIKE $strikeCount / 3',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: themeColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Main Message
            Text(
              isCritical
                  ? 'Three security strikes were registered against your session. The exam has been locked and automatically submitted for manual academic integrity audit.'
                  : (violation?.details ??
                      'An action violating proctoring protocols was intercepted (window blur or prohibited shortcut).'),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colors.fgPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // Details card
            if (violation != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_toggle_off, size: 13, color: colors.fgSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Violation: ${violation!.title}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.fgSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trust Penalty: -${violation!.trustPenalty.toStringAsFixed(0)}% trust rating',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCritical ? colors.accentRose : colors.accentAmber,
                  foregroundColor: isCritical ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isCritical ? 'Acknowledge & Exit' : 'I Understand & Resume Exam',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
