import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../models/proctored_exam_model.dart';

class ExamCompletionCertificateDialog extends StatelessWidget {
  final ExamCertificate certificate;
  final VoidCallback onClose;

  const ExamCompletionCertificateDialog({
    super.key,
    required this.certificate,
    required this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required ExamCertificate certificate,
    required VoidCallback onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: ExamCompletionCertificateDialog(
          certificate: certificate,
          onClose: () {
            Navigator.of(ctx).pop();
            onClose();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isHonors = certificate.tier == ExamIntegrityTier.verifiedHonors;
    final isDisqualified = certificate.tier == ExamIntegrityTier.disqualified;
    final accentColor = isDisqualified
        ? colors.accentRose
        : (isHonors ? colors.accentCyan : colors.accentEmerald);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 580,
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Accent Ribbon
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.2),
                    accentColor,
                    accentColor.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                children: [
                  // Verification Seal & Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.12),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Icon(
                      isDisqualified
                          ? Icons.block_flipped
                          : (isHonors ? Icons.workspace_premium : Icons.verified),
                      color: accentColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    isDisqualified
                        ? 'EXAM INTEGRITY AUDIT FAILED'
                        : 'OFFICIAL CERTIFICATE OF MASTERY',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    certificate.courseTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.fgPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Awarded to: ${certificate.learnerName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.fgSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metrics Quad Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderSubtle, width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric(
                          label: 'FINAL SCORE',
                          value: '${certificate.scorePercent.toStringAsFixed(0)}%',
                          color: certificate.scorePercent >= 70
                              ? colors.accentEmerald
                              : colors.accentAmber,
                          colors: colors,
                        ),
                        _buildMetric(
                          label: 'MARKS EARNED',
                          value: '${certificate.marksEarned > 0 ? certificate.marksEarned.toStringAsFixed(1) : certificate.correctAnswers}/${certificate.totalMarksAvailable > 0 ? certificate.totalMarksAvailable.toStringAsFixed(0) : certificate.totalQuestions}',
                          color: colors.fgPrimary,
                          colors: colors,
                        ),
                        _buildMetric(
                          label: 'TRUST SCORE',
                          value: '${certificate.trustScore.toStringAsFixed(0)}%',
                          color: accentColor,
                          colors: colors,
                        ),
                        _buildMetric(
                          label: 'XP REWARD',
                          value: '+${certificate.xpEarned}',
                          color: colors.accentAmber,
                          colors: colors,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status / Integrity Tier Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDisqualified ? Icons.error_outline : Icons.shield_outlined,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDisqualified
                              ? 'Status: Disqualified due to Proctoring Strikes'
                              : (isHonors
                                  ? 'Verified Honors: Proctored with Zero / Minor Anomalies'
                                  : 'Standard Completion: Passed Proctored Evaluation'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // AI Examiner Subjective Feedback Section
                  if (certificate.evaluations.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderSubtle, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology_outlined, size: 14, color: colors.accentCyan),
                              const SizedBox(width: 6),
                              Text(
                                'AI EXAMINER SUBJECTIVE REPORT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: colors.accentCyan,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: certificate.evaluations.length,
                              itemBuilder: (context, index) {
                                final eval = certificate.evaluations[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colors.bgBase,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: colors.borderSubtle, width: 0.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            eval.topicTag,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: colors.fgPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${eval.marksEarned.toStringAsFixed(1)} / ${eval.maxMarks.toStringAsFixed(0)} Marks',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: eval.scorePercent >= 60 ? colors.accentEmerald : colors.accentAmber,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        eval.feedback,
                                        style: TextStyle(fontSize: 10, height: 1.3, color: colors.fgSecondary),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Digital Hash
                  Text(
                    'CERTIFICATE ID: ${certificate.certificateId}',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                      color: colors.fgTertiary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: ThemeData.estimateBrightnessForColor(accentColor) == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isDisqualified ? 'Return to Workspace' : 'Claim Certificate & Finish',
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
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
    required AppColorsExtension colors,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: colors.fgSecondary,
          ),
        ),
      ],
    );
  }
}
