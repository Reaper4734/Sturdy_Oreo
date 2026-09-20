import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../models/proctored_exam_model.dart';
import '../../services/webcam_platform.dart';

class WebcamProctorHud extends StatefulWidget {
  final bool isViolating;
  final int strikeCount;
  final double trustScore;
  final ValueChanged<double>? onAudioAnomaly;
  final ValueChanged<BiometricTelemetry>? onBiometrics;

  const WebcamProctorHud({
    super.key,
    this.isViolating = false,
    required this.strikeCount,
    required this.trustScore,
    this.onAudioAnomaly,
    this.onBiometrics,
  });

  @override
  State<WebcamProctorHud> createState() => _WebcamProctorHudState();
}

class _WebcamProctorHudState extends State<WebcamProctorHud>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  BiometricTelemetry _telemetry = const BiometricTelemetry(
    isCameraActive: false,
    status: FacePresenceStatus.noFaceDetected,
  );
  int _sustainedSpeechCount = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAlert = widget.isViolating ||
        widget.strikeCount >= 2 ||
        _telemetry.status == FacePresenceStatus.multipleFaces ||
        _telemetry.status == FacePresenceStatus.eyesClosedSustained ||
        (_telemetry.status == FacePresenceStatus.noFaceDetected && _telemetry.isCameraActive);

    final isWarning = widget.strikeCount == 1 ||
        _telemetry.status == FacePresenceStatus.eyesLookingAway ||
        _telemetry.status == FacePresenceStatus.headTurnedAway;

    final primaryHudColor = isAlert
        ? colors.accentRose
        : (isWarning ? colors.accentAmber : colors.accentCyan);

    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlert ? colors.accentRose : colors.borderSubtle,
          width: isAlert ? 1.5 : 1.0,
        ),
        boxShadow: AppElevation.low,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // 1. Live Browser Webcam Feed
            Positioned.fill(
              child: createWebcamView(
                onBiometrics: (telemetry) {
                  if (!mounted) return;
                  setState(() {
                    _telemetry = telemetry;
                    if (telemetry.audioDb > 68.0) {
                      _sustainedSpeechCount++;
                      if (_sustainedSpeechCount >= 3) {
                        widget.onAudioAnomaly?.call(telemetry.audioDb);
                        _sustainedSpeechCount = 0;
                      }
                    } else {
                      _sustainedSpeechCount = 0;
                    }
                  });
                  widget.onBiometrics?.call(telemetry);
                },
              ),
            ),

            // Semi-transparent HUD tint over camera
            Positioned.fill(
              child: Container(
                color: colors.bgElevated.withValues(alpha: _telemetry.isCameraActive ? 0.15 : 0.90),
              ),
            ),

            // 2. High-Tech Grid Overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _HudGridPainter(
                  gridColor: colors.borderSubtle.withValues(alpha: 0.25),
                ),
              ),
            ),

            // 3. Dynamic MediaPipe 3D Face Mesh, Iris Tracking & Bounding Box
            Positioned.fill(
              child: CustomPaint(
                painter: _MediaPipeFaceMeshPainter(
                  telemetry: _telemetry,
                  color: primaryHudColor,
                  pulseFactor: math.sin(_animController.value * math.pi * 2),
                ),
              ),
            ),

            // 4. Sweeping Laser Scan Line
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final topOffset = _animController.value * 190;
                return Positioned(
                  top: topOffset,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          primaryHudColor.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryHudColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 5. Corner Targeting Brackets
            Positioned.fill(
              child: CustomPaint(
                painter: _CornerBracketsPainter(
                  color: primaryHudColor.withValues(alpha: 0.7),
                ),
              ),
            ),

            // 6. Top Status Bar with Head Pose & Gaze Radar
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: primaryHudColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryHudColor.withValues(alpha: 0.8),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getStatusLabel(_telemetry),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: primaryHudColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Head Pose & Eye Gaze Compass Radar
                  _buildHeadPoseRadar(_telemetry, primaryHudColor, colors),
                ],
              ),
            ),

            // 7. Bottom Biometric Telemetry Bar & Audio Equalizer
            Positioned(
              bottom: 6,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Icon(
                    _telemetry.isCameraActive ? Icons.videocam : Icons.videocam_outlined,
                    size: 11,
                    color: _telemetry.isCameraActive ? colors.accentEmerald : colors.fgSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'MEDIAPIPE 468-PT 3D MESH',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: _telemetry.isCameraActive ? colors.accentEmerald : colors.fgSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Live 8-Band Cyberpunk Equalizer Spectrum
                  _buildAudioEqualizer(_telemetry, colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(BiometricTelemetry t) {
    if (!t.isCameraActive) return 'SENTINEL: CAMERA OFFLINE';
    switch (t.status) {
      case FacePresenceStatus.lockedSingle:
        return '3D MESH LOCKED (${t.confidencePercent.toStringAsFixed(1)}%)';
      case FacePresenceStatus.blinking:
        return 'BLINK [NOMINAL] (EAR ${t.eyeAspectRatio.toStringAsFixed(2)})';
      case FacePresenceStatus.eyesLookingAway:
        return 'EYES AWAY [${(t.gazeOffset * 100).abs().toStringAsFixed(0)}% GAZE DRIFT]';
      case FacePresenceStatus.headTurnedAway:
        return 'FACE AWAY [${t.headYaw.toStringAsFixed(0)}° YAW / ${t.headPitch.toStringAsFixed(0)}° PITCH]';
      case FacePresenceStatus.eyesClosedSustained:
        return 'ALERT: EYES CLOSED > 2.5s';
      case FacePresenceStatus.noFaceDetected:
        return 'ALERT: CANDIDATE ABSENT';
      case FacePresenceStatus.multipleFaces:
        return 'ALERT: ${t.faceCount} FACES DETECTED';
    }
  }

  Widget _buildHeadPoseRadar(BiometricTelemetry t, Color primaryColor, AppColorsExtension colors) {
    final yaw = (t.headYaw / 45.0).clamp(-1.0, 1.0);
    final pitch = (t.headPitch / 30.0).clamp(-1.0, 1.0);
    final gazeH = t.gazeOffset.clamp(-1.0, 1.0);

    return Tooltip(
      message: 'Head Pose: Yaw ${t.headYaw.toStringAsFixed(1)}°, Pitch ${t.headPitch.toStringAsFixed(1)}° | Iris Gaze: ${(t.gazeOffset * 100).toStringAsFixed(0)}% | EAR: ${t.eyeAspectRatio.toStringAsFixed(2)}',
      child: Container(
        width: 36,
        height: 20,
        decoration: BoxDecoration(
          color: colors.bgCanvas.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.borderSubtle, width: 0.6),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center reticle
            Container(width: 2, height: 2, color: colors.fgSecondary.withValues(alpha: 0.4)),
            // Head orientation dot
            Align(
              alignment: Alignment(yaw, pitch),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Iris Gaze Vector indicator (smaller cyan ring)
            if (t.isNominal || t.status == FacePresenceStatus.eyesLookingAway)
              Align(
                alignment: Alignment(gazeH, pitch * 0.5),
                child: Container(
                  width: 2.5,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioEqualizer(BiometricTelemetry t, AppColorsExtension colors) {
    final waveform = t.audioWaveform.isNotEmpty ? t.audioWaveform : List.filled(8, 0.1);
    final isLoud = t.audioDb > 65.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isLoud
            ? colors.accentRose.withValues(alpha: 0.2)
            : colors.bgCanvas.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isLoud ? colors.accentRose : colors.borderSubtle,
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            size: 10,
            color: isLoud ? colors.accentRose : colors.accentCyan,
          ),
          const SizedBox(width: 4),
          // 8-Band Equalizer Spectrum
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(waveform.length, (i) {
              final amp = (waveform[i] * 9.0).clamp(1.5, 10.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.8),
                width: 1.8,
                height: amp,
                decoration: BoxDecoration(
                  color: isLoud ? colors.accentRose : colors.accentCyan,
                  borderRadius: BorderRadius.circular(0.8),
                ),
              );
            }),
          ),
          const SizedBox(width: 4),
          Text(
            '${t.audioDb.toStringAsFixed(0)} dB',
            style: TextStyle(
              fontSize: 8.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: isLoud ? colors.accentRose : colors.fgSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudGridPainter extends CustomPainter {
  final Color gridColor;

  _HudGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HudGridPainter oldDelegate) => false;
}

class _CornerBracketsPainter extends CustomPainter {
  final Color color;

  _CornerBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    const len = 10.0;
    const pad = 5.0;

    // Top-Left
    canvas.drawLine(const Offset(pad, pad + len), const Offset(pad, pad), paint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + len, pad), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width - pad - len, pad), Offset(size.width - pad, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad, pad + len), paint);

    // Bottom-Left
    canvas.drawLine(Offset(pad, size.height - pad - len), Offset(pad, size.height - pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad + len, size.height - pad), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - pad - len, size.height - pad), Offset(size.width - pad, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad), Offset(size.width - pad, size.height - pad - len), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) => oldDelegate.color != color;
}

class _MediaPipeFaceMeshPainter extends CustomPainter {
  final BiometricTelemetry telemetry;
  final Color color;
  final double pulseFactor;

  _MediaPipeFaceMeshPainter({
    required this.telemetry,
    required this.color,
    required this.pulseFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!telemetry.isCameraActive) return;

    final paintMesh = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final paintIris = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    final box = telemetry.faceBoundingBox;

    if (box != null) {
      // 1. Dynamic Physical Bounding Box that tracks real face
      final rectPx = Rect.fromLTWH(
        box.left * size.width,
        box.top * size.height,
        box.width * size.width,
        box.height * size.height,
      );

      final paintBox = Paint()
        ..color = color.withValues(alpha: 0.65)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // Draw bounding box corners
      const cornerLen = 8.0;
      canvas.drawLine(rectPx.topLeft, Offset(rectPx.left + cornerLen, rectPx.top), paintBox);
      canvas.drawLine(rectPx.topLeft, Offset(rectPx.left, rectPx.top + cornerLen), paintBox);

      canvas.drawLine(rectPx.topRight, Offset(rectPx.right - cornerLen, rectPx.top), paintBox);
      canvas.drawLine(rectPx.topRight, Offset(rectPx.right, rectPx.top + cornerLen), paintBox);

      canvas.drawLine(rectPx.bottomLeft, Offset(rectPx.left + cornerLen, rectPx.bottom), paintBox);
      canvas.drawLine(rectPx.bottomLeft, Offset(rectPx.left, rectPx.bottom - cornerLen), paintBox);

      canvas.drawLine(rectPx.bottomRight, Offset(rectPx.right - cornerLen, rectPx.bottom), paintBox);
      canvas.drawLine(rectPx.bottomRight, Offset(rectPx.right, rectPx.bottom - cornerLen), paintBox);

      // 2. Real 3D MediaPipe Mesh Landmark Points
      if (telemetry.landmarks.isNotEmpty) {
        for (final pt in telemetry.landmarks) {
          final px = Offset(pt.x * size.width, pt.y * size.height);
          canvas.drawCircle(px, 1.2, paintDot);
        }
      }

      // 3. Iris Tracking Reticles & Gaze Vectors
      if (telemetry.isBlinking) {
        // Subtle closed eyelid bar
        if (telemetry.leftEye != null) {
          final lPx = Offset(telemetry.leftEye!.dx * size.width, telemetry.leftEye!.dy * size.height);
          canvas.drawLine(Offset(lPx.dx - 6, lPx.dy), Offset(lPx.dx + 6, lPx.dy), paintMesh);
        }
        if (telemetry.rightEye != null) {
          final rPx = Offset(telemetry.rightEye!.dx * size.width, telemetry.rightEye!.dy * size.height);
          canvas.drawLine(Offset(rPx.dx - 6, rPx.dy), Offset(rPx.dx + 6, rPx.dy), paintMesh);
        }
      } else {
        if (telemetry.leftIris != null) {
          final irisPx = Offset(telemetry.leftIris!.dx * size.width, telemetry.leftIris!.dy * size.height);
          canvas.drawCircle(irisPx, 2.2, paintIris);
          canvas.drawCircle(irisPx, 4.5, paintMesh);
          // Gaze vector ray
          final gazeVec = Offset(telemetry.gazeOffset * 8.0, telemetry.verticalGazeOffset * 6.0);
          canvas.drawLine(irisPx, irisPx + gazeVec, paintMesh);
        }

        if (telemetry.rightIris != null) {
          final irisPx = Offset(telemetry.rightIris!.dx * size.width, telemetry.rightIris!.dy * size.height);
          canvas.drawCircle(irisPx, 2.2, paintIris);
          canvas.drawCircle(irisPx, 4.5, paintMesh);
          // Gaze vector ray
          final gazeVec = Offset(telemetry.gazeOffset * 8.0, telemetry.verticalGazeOffset * 6.0);
          canvas.drawLine(irisPx, irisPx + gazeVec, paintMesh);
        }
      }

      // 4. Center Crosshair on Nose
      if (telemetry.noseTip != null) {
        final nosePx = Offset(telemetry.noseTip!.dx * size.width, telemetry.noseTip!.dy * size.height);
        canvas.drawLine(Offset(nosePx.dx - 4, nosePx.dy), Offset(nosePx.dx + 4, nosePx.dy), paintMesh);
        canvas.drawLine(Offset(nosePx.dx, nosePx.dy - 4), Offset(nosePx.dx, nosePx.dy + 4), paintMesh);
      }
    } else {
      // Nominal searching target crosshair when no face locked
      final center = Offset(size.width / 2, size.height / 2);
      final w = size.width * (0.45 + pulseFactor * 0.02);
      final h = size.height * (0.60 + pulseFactor * 0.02);
      final rect = Rect.fromCenter(center: center, width: w, height: h);

      final paintDashed = Paint()
        ..color = color.withValues(alpha: 0.40)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawOval(rect, paintDashed);
      canvas.drawLine(Offset(center.dx - 6, center.dy), Offset(center.dx + 6, center.dy), paintDashed);
      canvas.drawLine(Offset(center.dx, center.dy - 6), Offset(center.dx, center.dy + 6), paintDashed);
    }
  }

  @override
  bool shouldRepaint(covariant _MediaPipeFaceMeshPainter oldDelegate) => true;
}
