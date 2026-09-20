import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../models/proctored_exam_model.dart';

class ExamConfigurationDialog extends StatefulWidget {
  final String courseTitle;
  final Function(int durationMinutes, MarkingScheme scheme) onStartExam;

  const ExamConfigurationDialog({
    super.key,
    required this.courseTitle,
    required this.onStartExam,
  });

  static Future<void> show(
    BuildContext context, {
    required String courseTitle,
    required Function(int durationMinutes, MarkingScheme scheme) onStartExam,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ExamConfigurationDialog(
        courseTitle: courseTitle,
        onStartExam: (dur, scheme) {
          Navigator.of(ctx).pop();
          onStartExam(dur, scheme);
        },
      ),
    );
  }

  @override
  State<ExamConfigurationDialog> createState() => _ExamConfigurationDialogState();
}

class _ExamConfigurationDialogState extends State<ExamConfigurationDialog> {
  int _selectedDuration = 30; // 30 min default
  MarkingScheme _selectedScheme = MarkingScheme.hybridUniversity;

  final List<Map<String, dynamic>> _durationTiers = [
    {'mins': 15, 'label': '15 Min', 'subtitle': 'Sprint Check (5 Qs)'},
    {'mins': 30, 'label': '30 Min', 'subtitle': 'Module Exam (10 Qs)'},
    {'mins': 60, 'label': '60 Min', 'subtitle': 'Midterm (20 Qs)'},
    {'mins': 120, 'label': '120 Min', 'subtitle': 'Capstone (40 Qs)'},
    {'mins': 180, 'label': '180 Min', 'subtitle': 'University Final (60 Qs)'},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 620,
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle, width: 1.0),
          boxShadow: AppElevation.high,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top University Header Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: colors.bgActivityBar,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.school_outlined, size: 18, color: colors.accentCyan),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UNIVERSITY PROCTORED EXAMINATION BRIEFING',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: colors.accentCyan,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.courseTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.fgPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Duration Selector
                  Text(
                    '1. SELECT EXAMINATION TIME LIMIT',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: colors.fgSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _durationTiers.map((tier) {
                      final isSelected = _selectedDuration == tier['mins'];
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => setState(() => _selectedDuration = tier['mins']),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.accentCyan.withValues(alpha: 0.15)
                                    : colors.bgSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? colors.accentCyan : colors.borderSubtle,
                                  width: isSelected ? 1.5 : 0.8,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    tier['label'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? colors.accentCyan : colors.fgPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tier['subtitle'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: colors.fgSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 2. Marking Scheme Selector
                  Text(
                    '2. EVALUATION & MARKING SCHEME',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: colors.fgSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSchemeCard(
                    scheme: MarkingScheme.hybridUniversity,
                    title: 'University Hybrid (Modern Evaluation)',
                    description: 'Section A: Objective Concepts + Section B: 15-Mark Subjective Architectural & Code Problems evaluated by AI tutor.',
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _buildSchemeCard(
                    scheme: MarkingScheme.negativePenalty,
                    title: 'Competitive Examination (+4 / -1)',
                    description: '+4 marks for correct answers, -1 mark penalty for incorrect attempts. Penalizes guessing.',
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _buildSchemeCard(
                    scheme: MarkingScheme.standard,
                    title: 'Standard Formative (+1 / 0)',
                    description: '+1 mark per correct answer with zero penalty for mistakes. Low-stress assessment.',
                    colors: colors,
                  ),
                  const SizedBox(height: 20),

                  // 3. Proctoring & System Readiness Checklist
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.borderSubtle, width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCheckItem(Icons.videocam_outlined, 'Camera Active', colors),
                        _buildCheckItem(Icons.mic_none_outlined, 'Audio Monitored', colors),
                        _buildCheckItem(Icons.shield_outlined, 'Anti-Cheat Sentinel', colors),
                        _buildCheckItem(Icons.cloud_done_outlined, 'Ledger Auto-Save', colors),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Start Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onStartExam(_selectedDuration, _selectedScheme),
                      icon: const Icon(Icons.lock_clock, size: 16),
                      label: Text(
                        'Launch $_selectedDuration-Minute Proctored Exam',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentCyan,
                        foregroundColor: ThemeData.estimateBrightnessForColor(colors.accentCyan) == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
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

  Widget _buildSchemeCard({
    required MarkingScheme scheme,
    required String title,
    required String description,
    required AppColorsExtension colors,
  }) {
    final isSelected = _selectedScheme == scheme;

    return InkWell(
      onTap: () => setState(() => _selectedScheme = scheme),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentCyan.withValues(alpha: 0.12) : colors.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.accentCyan : colors.borderSubtle,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? colors.accentCyan : colors.fgSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colors.accentCyan : colors.fgPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 10, color: colors.fgSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(IconData icon, String label, AppColorsExtension colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.accentEmerald),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: colors.fgPrimary),
        ),
      ],
    );
  }
}
