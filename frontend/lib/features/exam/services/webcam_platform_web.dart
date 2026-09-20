// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import '../models/proctored_exam_model.dart';

bool _isWebcamViewRegistered = false;
Timer? _audioMeterTimer;
Timer? _fallbackVisionTimer;
void Function(String type)? _globalClipboardViolationHandler;

void registerClipboardViolationHandler(void Function(String type) handler) {
  _globalClipboardViolationHandler = handler;
}

Widget createWebcamView({
  required void Function(BiometricTelemetry telemetry) onBiometrics,
}) {
  if (!_isWebcamViewRegistered) {
    _isWebcamViewRegistered = true;

    // Register browser-level copy / paste / cut interceptors for anti-cheat
    html.document.onCopy.listen((e) {
      e.preventDefault();
      _globalClipboardViolationHandler?.call('copy');
    });

    html.document.onPaste.listen((e) {
      e.preventDefault();
      _globalClipboardViolationHandler?.call('paste');
    });

    html.document.onCut.listen((e) {
      e.preventDefault();
      _globalClipboardViolationHandler?.call('cut');
    });

    ui_web.platformViewRegistry.registerViewFactory('proctor-live-webcam-feed', (int viewId) {
      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)'; // Mirror camera feed for realistic proctoring feedback

      double currentAudioDb = 32.0;
      List<double> currentWaveform = List.filled(8, 0.0);

      if (html.window.navigator.mediaDevices != null) {
        html.window.navigator.mediaDevices!.getUserMedia({
          'video': {
            'width': {'ideal': 640},
            'height': {'ideal': 480},
            'facingMode': 'user'
          },
          'audio': true,
        }).then((stream) {
          video.srcObject = stream;
          video.play();

          // 1. Web Audio Frequency Spectrum Analyzer
          try {
            final audioCtxConstructor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
            if (audioCtxConstructor != null) {
              final audioCtx = js.JsObject(audioCtxConstructor as js.JsFunction, []);
              final source = audioCtx.callMethod('createMediaStreamSource', [stream]) as js.JsObject;
              final analyser = audioCtx.callMethod('createAnalyser', []) as js.JsObject;
              analyser['fftSize'] = 64; // 32 bins
              source.callMethod('connect', [analyser]);

              final int bufferLength = (analyser['frequencyBinCount'] as num).toInt();
              final data = Uint8List(bufferLength);

              _audioMeterTimer?.cancel();
              _audioMeterTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
                if (bufferLength == 0) return;
                analyser.callMethod('getByteFrequencyData', [data]);

                double sumSquares = 0;
                for (int i = 0; i < bufferLength; i++) {
                  sumSquares += data[i] * data[i];
                }
                final rms = math.sqrt(sumSquares / bufferLength);
                currentAudioDb = rms > 0
                    ? (20 * math.log(rms + 1) / math.ln10 * 1.5 + 26.0).clamp(28.0, 92.0)
                    : 32.0;

                final bands = <double>[];
                const bandSize = 4;
                for (int b = 0; b < 8; b++) {
                  double bandSum = 0;
                  final start = b * bandSize;
                  for (int k = 0; k < bandSize && (start + k) < bufferLength; k++) {
                    bandSum += data[start + k];
                  }
                  final avg = bandSum / bandSize;
                  bands.add((avg / 255.0).clamp(0.0, 1.0));
                }
                currentWaveform = bands;
              });
            }
          } catch (_) {}

          // 2. MediaPipe 468-point 3D Face Mesh Pipeline
          bool mediaPipeConnected = false;
          try {
            if (js.context.hasProperty('OreoFaceMesh')) {
              final oreoFaceMesh = js.context['OreoFaceMesh'] as js.JsObject;
              oreoFaceMesh.callMethod('start', [
                video,
                (js.JsObject data) {
                  mediaPipeConnected = true;
                  final statusStr = data['status'] as String? ?? 'NO_FACE';
                  FacePresenceStatus status;
                  if (statusStr == 'MULTIPLE_FACES') {
                    status = FacePresenceStatus.multipleFaces;
                  } else if (statusStr == 'ATTENTION_DRIFT') {
                    status = FacePresenceStatus.attentionDrift;
                  } else if (statusStr == 'LOCKED_SINGLE') {
                    status = FacePresenceStatus.lockedSingle;
                  } else {
                    status = FacePresenceStatus.noFaceDetected;
                  }

                  final int faceCount = (data['faceCount'] as num?)?.toInt() ?? 0;
                  final double confidence = ((data['confidence'] as num?)?.toDouble() ?? 0.0) * 100.0;
                  final double yaw = (data['yaw'] as num?)?.toDouble() ?? 0.0;
                  final double pitch = (data['pitch'] as num?)?.toDouble() ?? 0.0;
                  final double gaze = (data['gaze'] as num?)?.toDouble() ?? 0.0;

                  ui.Rect? box;
                  if (data['box'] != null) {
                    final b = data['box'] as js.JsObject;
                    final bx = (b['x'] as num).toDouble();
                    final by = (b['y'] as num).toDouble();
                    final bw = (b['w'] as num).toDouble();
                    final bh = (b['h'] as num).toDouble();
                    box = ui.Rect.fromLTWH(bx.clamp(0.0, 1.0), by.clamp(0.0, 1.0), bw.clamp(0.05, 1.0), bh.clamp(0.05, 1.0));
                  }

                  ui.Offset? parsePoint(String key) {
                    if (data[key] == null) return null;
                    final p = data[key] as js.JsObject;
                    return ui.Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble());
                  }

                  final leftEye = parsePoint('leftEye');
                  final rightEye = parsePoint('rightEye');
                  final leftIris = parsePoint('leftIris');
                  final rightIris = parsePoint('rightIris');
                  final nose = parsePoint('nose');
                  final mouth = parsePoint('mouth');

                  final landmarksList = <BiometricLandmark>[];
                  if (data['landmarks'] != null) {
                    final lms = data['landmarks'] as js.JsArray;
                    for (int i = 0; i < lms.length; i++) {
                      final pt = lms[i] as js.JsObject;
                      landmarksList.add(BiometricLandmark(
                        x: (pt['x'] as num).toDouble(),
                        y: (pt['y'] as num).toDouble(),
                        z: (pt['z'] as num?)?.toDouble() ?? 0.0,
                      ));
                    }
                  }

                  onBiometrics(BiometricTelemetry(
                    isCameraActive: true,
                    status: status,
                    faceCount: faceCount,
                    confidencePercent: confidence,
                    faceBoundingBox: box,
                    leftEye: leftEye,
                    rightEye: rightEye,
                    leftIris: leftIris,
                    rightIris: rightIris,
                    noseTip: nose,
                    mouthCenter: mouth,
                    headYaw: yaw,
                    headPitch: pitch,
                    gazeOffset: gaze,
                    audioDb: currentAudioDb,
                    audioWaveform: currentWaveform,
                    landmarks: landmarksList,
                  ));
                }
              ]);
            }
          } catch (e) {
            mediaPipeConnected = false;
          }

          // Fallback Computer Vision if MediaPipe takes time to load
          if (!mediaPipeConnected) {
            final offscreenCanvas = html.CanvasElement(width: 120, height: 90);
            final offscreenCtx = offscreenCanvas.context2D;

            _fallbackVisionTimer?.cancel();
            _fallbackVisionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
              if (mediaPipeConnected || video.readyState < 2) return;

              try {
                offscreenCtx.drawImageScaled(video, 0, 0, 120, 90);
                final imgData = offscreenCtx.getImageData(0, 0, 120, 90);
                final d = imgData.data;

                int total = 120 * 90;
                double lum = 0;
                double skin = 0;
                double wx = 0, wy = 0;

                for (int i = 0; i < d.length; i += 4) {
                  final r = d[i];
                  final g = d[i + 1];
                  final b = d[i + 2];
                  lum += 0.299 * r + 0.587 * g + 0.114 * b;
                  if (r > 80 && g > 35 && b > 20 && r > g && r > b && (r - g).abs() > 12) {
                    skin++;
                    final idx = i ~/ 4;
                    wx += idx % 120;
                    wy += idx ~/ 120;
                  }
                }

                final avgLum = lum / total;
                final skinRatio = skin / total;

                if (avgLum < 12.0 || avgLum > 248.0 || skinRatio < 0.04) {
                  onBiometrics(BiometricTelemetry(
                    isCameraActive: true,
                    status: FacePresenceStatus.noFaceDetected,
                    faceCount: 0,
                    confidencePercent: 0.0,
                    audioDb: currentAudioDb,
                    audioWaveform: currentWaveform,
                  ));
                } else {
                  final cx = (wx / skin) / 120.0;
                  final cy = (wy / skin) / 90.0;
                  final w = (math.sqrt(skinRatio) * 1.3).clamp(0.25, 0.65);
                  final h = (w * 1.3).clamp(0.30, 0.80);
                  final mirroredCx = 1.0 - cx;

                  final rect = ui.Rect.fromCenter(
                    center: ui.Offset(mirroredCx.clamp(0.2, 0.8), cy.clamp(0.2, 0.8)),
                    width: w,
                    height: h,
                  );

                  final yaw = ((mirroredCx - 0.5) * 60.0).clamp(-45.0, 45.0);
                  final status = yaw.abs() > 24.0 ? FacePresenceStatus.attentionDrift : FacePresenceStatus.lockedSingle;

                  onBiometrics(BiometricTelemetry(
                    isCameraActive: true,
                    status: status,
                    faceCount: 1,
                    confidencePercent: 97.5,
                    faceBoundingBox: rect,
                    leftEye: ui.Offset(rect.left + rect.width * 0.30, rect.top + rect.height * 0.35),
                    rightEye: ui.Offset(rect.left + rect.width * 0.70, rect.top + rect.height * 0.35),
                    noseTip: ui.Offset(rect.left + rect.width * 0.50, rect.top + rect.height * 0.55),
                    mouthCenter: ui.Offset(rect.left + rect.width * 0.50, rect.top + rect.height * 0.75),
                    headYaw: yaw,
                    headPitch: 0.0,
                    audioDb: currentAudioDb,
                    audioWaveform: currentWaveform,
                  ));
                }
              } catch (_) {}
            });
          }
        }).catchError((_) {
          onBiometrics(const BiometricTelemetry(
            isCameraActive: false,
            status: FacePresenceStatus.noFaceDetected,
          ));
        });
      } else {
        onBiometrics(const BiometricTelemetry(
          isCameraActive: false,
          status: FacePresenceStatus.noFaceDetected,
        ));
      }

      return video;
    });
  }

  return const HtmlElementView(viewType: 'proctor-live-webcam-feed');
}

bool get isWebcamPlatformSupported => true;
