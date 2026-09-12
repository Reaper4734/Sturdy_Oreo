import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import 'dashboard_illustrations.dart';

class NextUpBentoCard extends StatelessWidget {
  final String nextModuleTitle;
  final String nextModuleDescription;
  final int conceptsNeededToUnlock;
  final VoidCallback onPreview;

  const NextUpBentoCard({
    super.key,
    required this.nextModuleTitle,
    required this.nextModuleDescription,
    this.conceptsNeededToUnlock = 2,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayTitle = nextModuleTitle.isNotEmpty ? nextModuleTitle : 'Upcoming Concept Module';
    final displayDesc = nextModuleDescription.isNotEmpty
        ? nextModuleDescription
        : 'Deep dive patterns and advanced applications';

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
          // Header Row: Icon + Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: Color(0xFF818CF8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Next Up',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.fgPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Body: Text details on left, Notepad Illustration on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.fgPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.fgSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Lock Requirement Banner
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 13, color: colors.fgSecondary),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            conceptsNeededToUnlock > 0
                                ? 'Complete $conceptsNeededToUnlock more concepts to unlock'
                                : 'Ready to begin in studio',
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
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right Vector Graphic
              const ChecklistNotepadIllustration(size: 90),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom Action: Preview Button
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onPreview,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.bgActivityBar,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.fgPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: colors.fgPrimary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
