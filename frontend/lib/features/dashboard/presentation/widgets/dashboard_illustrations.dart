import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Generic, resolution-independent vector illustrations for Oreo Dashboard.
/// Works for ANY learning field (Pharmacy, Computer Science, Law, Medicine, Design, etc.)

/// 1. Study Stack Illustration (Books + Interactive Learning Screen with Play Icon)
class StudyStackIllustration extends StatelessWidget {
  final double size;

  const StudyStackIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size * 0.9,
      child: CustomPaint(
        painter: _StudyStackPainter(
          isDark: isDark,
          screenColor: const Color(0xFF6366F1), // Indigo/Violet
          bookTopColor: const Color(0xFF38BDF8),  // Sky Blue
          bookMidColor: const Color(0xFF1E293B),  // Dark Slate
          bookBotColor: const Color(0xFFF59E0B),  // Amber
          leafColor: const Color(0xFF10B981),     // Emerald
          paperColor: isDark ? const Color(0xFF27272A) : const Color(0xFFFFFFFF),
          lineColor: colors.borderSubtle,
        ),
      ),
    );
  }
}

class _StudyStackPainter extends CustomPainter {
  final bool isDark;
  final Color screenColor;
  final Color bookTopColor;
  final Color bookMidColor;
  final Color bookBotColor;
  final Color leafColor;
  final Color paperColor;
  final Color lineColor;

  _StudyStackPainter({
    required this.isDark,
    required this.screenColor,
    required this.bookTopColor,
    required this.bookMidColor,
    required this.bookBotColor,
    required this.leafColor,
    required this.paperColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subtle Background Glow/Leaves
    final leafPaint = Paint()
      ..color = leafColor.withValues(alpha: isDark ? 0.35 : 0.25)
      ..style = PaintingStyle.fill;

    // Draw leafy accents behind screen
    final leafPath = Path();
    leafPath.moveTo(w * 0.82, h * 0.45);
    leafPath.quadraticBezierTo(w * 0.98, h * 0.28, w * 0.92, h * 0.15);
    leafPath.quadraticBezierTo(w * 0.78, h * 0.25, w * 0.82, h * 0.45);
    canvas.drawPath(leafPath, leafPaint);

    final leafPath2 = Path();
    leafPath2.moveTo(w * 0.88, h * 0.38);
    leafPath2.quadraticBezierTo(w * 0.99, h * 0.42, w * 0.96, h * 0.32);
    leafPath2.quadraticBezierTo(w * 0.88, h * 0.30, w * 0.88, h * 0.38);
    canvas.drawPath(leafPath2, leafPaint);

    // 2. Bottom Book (Amber spine)
    final botBookPaint = Paint()..color = bookBotColor;
    final botRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.72, w * 0.70, h * 0.14),
      const Radius.circular(6),
    );
    canvas.drawRRect(botRRect, botBookPaint);

    // Pages edge for bottom book
    final paperPaint = Paint()..color = paperColor;
    final botPaperRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.74, w * 0.60, h * 0.10),
      const Radius.circular(3),
    );
    canvas.drawRRect(botPaperRRect, paperPaint);

    // 3. Middle Book (Dark slate/blue spine)
    final midBookPaint = Paint()..color = isDark ? const Color(0xFF334155) : const Color(0xFF1E293B);
    final midRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.60, w * 0.74, h * 0.13),
      const Radius.circular(6),
    );
    canvas.drawRRect(midRRect, midBookPaint);

    final midPaperRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.62, w * 0.65, h * 0.09),
      const Radius.circular(3),
    );
    canvas.drawRRect(midPaperRRect, paperPaint);

    // 4. Top Book (Sky blue cover)
    final topBookPaint = Paint()..color = bookTopColor;
    final topRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.50, w * 0.64, h * 0.11),
      const Radius.circular(5),
    );
    canvas.drawRRect(topRRect, topBookPaint);

    // 5. Standing Digital Learning Display (Floating screen with play symbol)
    final screenPaint = Paint()..color = screenColor;
    final screenRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.14, w * 0.48, h * 0.38),
      const Radius.circular(8),
    );
    canvas.drawRRect(screenRRect, screenPaint);

    // Inner display glow
    final innerDisplayPaint = Paint()
      ..color = isDark ? const Color(0xFF4338CA) : const Color(0xFF4F46E5);
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.29, h * 0.17, w * 0.42, h * 0.32),
      const Radius.circular(6),
    );
    canvas.drawRRect(innerRRect, innerDisplayPaint);

    // Play button triangle (White)
    final playPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final playPath = Path();
    final centerX = w * 0.50;
    final centerY = h * 0.33;
    final playSize = w * 0.07;
    playPath.moveTo(centerX - playSize * 0.6, centerY - playSize * 0.8);
    playPath.lineTo(centerX + playSize * 0.8, centerY);
    playPath.lineTo(centerX - playSize * 0.6, centerY + playSize * 0.8);
    playPath.close();
    canvas.drawPath(playPath, playPaint);
  }

  @override
  bool shouldRepaint(covariant _StudyStackPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// 2. Target Bullseye Illustration (Goal / Daily Mission Focus)
class TargetBullseyeIllustration extends StatelessWidget {
  final double size;

  const TargetBullseyeIllustration({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BullseyePainter(isDark: isDark),
      ),
    );
  }
}

class _BullseyePainter extends CustomPainter {
  final bool isDark;

  _BullseyePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.48, size.height * 0.52);
    final radius = size.width * 0.38;

    // Rings (Amber / Orange theme)
    final outerRing = Paint()
      ..color = const Color(0xFFF97316) // Vibrant Orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08;
    canvas.drawCircle(center, radius, outerRing);

    final midRing = Paint()
      ..color = isDark ? const Color(0xFF27272A) : const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.72, midRing);

    final innerRing = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07;
    canvas.drawCircle(center, radius * 0.68, innerRing);

    final centerDot = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.28, centerDot);

    // Arrow hitting bullseye
    final arrowPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = size.width * 0.05
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arrowShaft = Path();
    arrowShaft.moveTo(center.dx + radius * 0.9, center.dy - radius * 0.9);
    arrowShaft.lineTo(center.dx, center.dy);
    canvas.drawPath(arrowShaft, arrowPaint);

    // Arrow feather fletching
    final featherPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    final feather = Path();
    final startX = center.dx + radius * 0.9;
    final startY = center.dy - radius * 0.9;
    feather.moveTo(startX, startY);
    feather.lineTo(startX + size.width * 0.08, startY - size.width * 0.04);
    feather.lineTo(startX + size.width * 0.04, startY - size.width * 0.08);
    feather.close();
    canvas.drawPath(feather, featherPaint);
  }

  @override
  bool shouldRepaint(covariant _BullseyePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// 3. Checklist Notepad Illustration (Next Up Module / Task Roadmap)
class ChecklistNotepadIllustration extends StatelessWidget {
  final double size;

  const ChecklistNotepadIllustration({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ChecklistPainter(isDark: isDark),
      ),
    );
  }
}

class _ChecklistPainter extends CustomPainter {
  final bool isDark;

  _ChecklistPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Notepad container (White / dark slate with subtle purple tint)
    final padPaint = Paint()
      ..color = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFFFFFF);
    final borderPaint = Paint()
      ..color = const Color(0xFF818CF8) // Indigo/Violet
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final padRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.15, w * 0.58, h * 0.72),
      const Radius.circular(10),
    );
    canvas.drawRRect(padRect, padPaint);
    canvas.drawRRect(padRect, borderPaint);

    // Spiral binding rings on top
    final ringPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final rx = w * 0.24 + i * (w * 0.10);
      canvas.drawLine(Offset(rx, h * 0.10), Offset(rx, h * 0.17), ringPaint);
    }

    // Checkmark rows
    final checkPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF3F3F46) : const Color(0xFFCBD5E1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final y = h * 0.32 + i * (h * 0.16);
      // checkmark
      final checkPath = Path();
      checkPath.moveTo(w * 0.24, y);
      checkPath.lineTo(w * 0.28, y + 4);
      checkPath.lineTo(w * 0.35, y - 4);
      canvas.drawPath(checkPath, checkPaint);

      // text line placeholder
      canvas.drawLine(Offset(w * 0.40, y), Offset(w * 0.64, y), linePaint);
    }

    // Floating Pen / Pencil (Purple/Violet)
    final penPaint = Paint()
      ..color = const Color(0xFFA855F7)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final penPath = Path();
    penPath.moveTo(w * 0.85, h * 0.52);
    penPath.lineTo(w * 0.72, h * 0.78);
    canvas.drawPath(penPath, penPaint);
  }

  @override
  bool shouldRepaint(covariant _ChecklistPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
