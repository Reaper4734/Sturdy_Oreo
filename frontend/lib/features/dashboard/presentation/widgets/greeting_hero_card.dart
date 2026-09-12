import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/mascot_provider.dart';
import 'mascot_selection_dialog.dart';
import 'mascot_widget.dart';

class GreetingBackgroundPainter extends CustomPainter {
  final AppColorsExtension colors;

  GreetingBackgroundPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    // Soft gradient circle behind the mascot
    final circlePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.accentPrimary.withValues(alpha: 0.15),
          colors.accentPrimary.withValues(alpha: 0.0),
        ],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.height))
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.height, circlePaint);

    // Subtle floating particles / tiny stars
    final random = Random(42); // fixed seed for determinism in rendering
    final particlePaint = Paint()..color = colors.fgPrimary.withValues(alpha: 0.1);
    
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), r, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GreetingHeroCard extends ConsumerWidget {
  final String greeting;
  final String learnerName;
  final String insight;

  const GreetingHeroCard({
    super.key,
    required this.greeting,
    required this.learnerName,
    required this.insight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mascotState = ref.watch(mascotProvider);
    final colors = context.colors;

    return Container(
      padding: AppSpacing.pXl,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: AppRadius.rXl,
        border: Border.all(color: colors.borderSubtle, width: 1),
        boxShadow: AppElevation.low,
      ),
      child: Row(
        children: [
          // Mascot Section (35%)
          Expanded(
            flex: 35,
            child: CustomPaint(
              painter: GreetingBackgroundPainter(colors: colors),
              child: SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const MascotSelectionDialog(type: MascotType.companion),
                        );
                      },
                      borderRadius: BorderRadius.circular(40),
                      child: MascotWidget(assetPath: 'assets/mascots/cube_pets/png/${mascotState.companionAsset}', size: 80),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const MascotSelectionDialog(type: MascotType.mentor),
                        );
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: MascotWidget(assetPath: 'assets/mascots/cube_characters/png/${mascotState.mentorAsset}', size: 100),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Greeting Section (65%)
          Expanded(
            flex: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$greeting, $learnerName',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.fgPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insight,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.fgSecondary,
                    height: 1.4,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
