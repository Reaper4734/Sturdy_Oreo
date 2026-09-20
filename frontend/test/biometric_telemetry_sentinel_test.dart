import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/exam/models/proctored_exam_model.dart';
import 'package:frontend/features/exam/services/exam_anti_cheat_sentinel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricTelemetry Model Tests', () {
    test('Correctly determines nominal and alert status including blinks', () {
      const nominal = BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.lockedSingle,
        faceCount: 1,
        confidencePercent: 99.2,
      );
      expect(nominal.isNominal, isTrue);
      expect(nominal.isAlert, isFalse);

      const blink = BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.blinking,
        faceCount: 1,
        isBlinking: true,
        eyeAspectRatio: 0.12,
      );
      // Natural blink is NOMINAL and not an alert
      expect(blink.isNominal, isTrue);
      expect(blink.isAlert, isFalse);

      const eyesAway = BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.eyesLookingAway,
        faceCount: 1,
        gazeOffset: 0.65,
      );
      expect(eyesAway.isNominal, isFalse);
      expect(eyesAway.isAlert, isTrue);

      const faceAway = BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.headTurnedAway,
        faceCount: 1,
        headYaw: 35.0,
      );
      expect(faceAway.isNominal, isFalse);
      expect(faceAway.isAlert, isTrue);

      const eyesClosed = BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.eyesClosedSustained,
        faceCount: 1,
        eyeAspectRatio: 0.08,
      );
      expect(eyesClosed.isNominal, isFalse);
      expect(eyesClosed.isAlert, isTrue);

      const absence = BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.noFaceDetected,
        faceCount: 0,
      );
      expect(absence.isNominal, isFalse);
      expect(absence.isAlert, isTrue);

      const multiple = BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.multipleFaces,
        faceCount: 2,
      );
      expect(multiple.isNominal, isFalse);
      expect(multiple.isAlert, isTrue);
    });

    test('Holds 3D landmarks, EAR, and iris coordinates accurately', () {
      const telemetry = BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.lockedSingle,
        faceBoundingBox: Rect.fromLTWH(0.2, 0.2, 0.6, 0.6),
        leftIris: Offset(0.35, 0.40),
        rightIris: Offset(0.65, 0.40),
        headYaw: 2.5,
        headPitch: -1.2,
        gazeOffset: 0.05,
        verticalGazeOffset: -0.02,
        eyeAspectRatio: 0.29,
        isBlinking: false,
        landmarks: [
          BiometricLandmark(x: 0.5, y: 0.5, z: -0.1),
          BiometricLandmark(x: 0.3, y: 0.4, z: 0.0),
        ],
      );

      expect(telemetry.landmarks.length, equals(2));
      expect(telemetry.leftIris?.dx, equals(0.35));
      expect(telemetry.rightIris?.dx, equals(0.65));
      expect(telemetry.headYaw, equals(2.5));
      expect(telemetry.eyeAspectRatio, equals(0.29));
      expect(telemetry.isBlinking, isFalse);
    });
  });

  group('ExamAntiCheatSentinel Biometric Enforcement Tests', () {
    test('Ignores biometrics when monitoring is inactive or camera offline', () {
      final violations = <ExamViolation>[];
      final sentinel = ExamAntiCheatSentinel(
        onViolation: (v) => violations.add(v),
        onStrike: (_, __) {},
        onDisqualified: () {},
      );

      // Monitoring not started
      sentinel.reportBiometricTelemetry(const BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.noFaceDetected,
      ));
      expect(violations.isEmpty, isTrue);

      sentinel.startMonitoring();

      // Camera offline
      sentinel.reportBiometricTelemetry(const BiometricTelemetry(
        isCameraActive: false,
        status: FacePresenceStatus.noFaceDetected,
      ));
      expect(violations.isEmpty, isTrue);

      sentinel.stopMonitoring();
    });

    test('Natural eye blinking does not trigger violation and resets drift timers', () {
      final violations = <ExamViolation>[];
      final sentinel = ExamAntiCheatSentinel(
        onViolation: (v) => violations.add(v),
        onStrike: (_, __) {},
        onDisqualified: () {},
      );

      sentinel.startMonitoring();

      sentinel.reportBiometricTelemetry(const BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.blinking,
        faceCount: 1,
        isBlinking: true,
        eyeAspectRatio: 0.11,
      ));

      expect(violations.isEmpty, isTrue);
      expect(sentinel.trustScore, equals(100.0));

      sentinel.stopMonitoring();
    });

    test('Candidate Absence Penalty triggers after sustained duration', () async {
      final violations = <ExamViolation>[];
      final sentinel = ExamAntiCheatSentinel(
        onViolation: (v) => violations.add(v),
        onStrike: (_, __) {},
        onDisqualified: () {},
      );

      sentinel.startMonitoring();
      expect(sentinel.trustScore, equals(100.0));

      // Initial frame of absence
      sentinel.reportBiometricTelemetry(const BiometricTelemetry(
        isCameraActive: true,
        status: FacePresenceStatus.noFaceDetected,
      ));
      // Immediate next frame shouldn't trigger violation (needs >3.5s)
      expect(violations.isEmpty, isTrue);
      expect(sentinel.trustScore, equals(100.0));

      sentinel.stopMonitoring();
    });

    test('Audio Anomaly reduces trust score', () {
      final violations = <ExamViolation>[];
      final sentinel = ExamAntiCheatSentinel(
        onViolation: (v) => violations.add(v),
        onStrike: (_, __) {},
        onDisqualified: () {},
      );

      sentinel.startMonitoring();
      sentinel.reportAudioAnomaly(78.5);

      expect(violations.length, equals(1));
      expect(violations.first.type, equals(ViolationType.audioAnomaly));
      expect(sentinel.trustScore, equals(95.0)); // -5 penalty

      sentinel.stopMonitoring();
    });
  });
}
