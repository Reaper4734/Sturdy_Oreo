import 'package:flutter/widgets.dart';

Widget createWebcamView({
  required void Function(bool active, double audioDb) onMetrics,
}) {
  return const SizedBox.shrink();
}

bool get isWebcamPlatformSupported => false;

void registerClipboardViolationHandler(void Function(String type) handler) {}
