import 'package:flutter/widgets.dart';
import '../models/proctored_exam_model.dart';

Widget createWebcamView({
  required void Function(BiometricTelemetry telemetry) onBiometrics,
}) {
  return const SizedBox.shrink();
}

bool get isWebcamPlatformSupported => false;

void registerClipboardViolationHandler(void Function(String type) handler) {}

