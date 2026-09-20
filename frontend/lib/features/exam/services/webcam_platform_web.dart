// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

bool _isWebcamViewRegistered = false;
Timer? _audioMeterTimer;
void Function(String type)? _globalClipboardViolationHandler;

void registerClipboardViolationHandler(void Function(String type) handler) {
  _globalClipboardViolationHandler = handler;
}

Widget createWebcamView({
  required void Function(bool active, double audioDb) onMetrics,
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
          onMetrics(true, 38.0);

          try {
            final audioCtxConstructor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
            if (audioCtxConstructor != null) {
              final audioCtx = js.JsObject(audioCtxConstructor as js.JsFunction, []);
              final source = audioCtx.callMethod('createMediaStreamSource', [stream]) as js.JsObject;
              final analyser = audioCtx.callMethod('createAnalyser', []) as js.JsObject;
              analyser['fftSize'] = 128;
              source.callMethod('connect', [analyser]);

              final int bufferLength = (analyser['frequencyBinCount'] as num).toInt();
              final data = Uint8List(bufferLength);
              _audioMeterTimer?.cancel();
              _audioMeterTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
                if (bufferLength == 0) return;
                analyser.callMethod('getByteFrequencyData', [data]);

                double sumSquares = 0;
                for (int i = 0; i < bufferLength; i++) {
                  sumSquares += data[i] * data[i];
                }
                final rms = math.sqrt(sumSquares / bufferLength);
                // Dynamic decibel calculation from acoustic frequency data (baseline ambient 28-92 dB)
                final db = rms > 0
                    ? (20 * math.log(rms + 1) / math.ln10 * 1.5 + 25.0).clamp(28.0, 92.0)
                    : 32.0;

                onMetrics(true, db);
              });
            }
          } catch (_) {
            // Web Audio API fallback to ambient acoustic baseline
            onMetrics(true, 38.0);
          }
        }).catchError((_) {
          // Camera permission denied or not available
          onMetrics(false, 0.0);
        });
      } else {
        onMetrics(false, 0.0);
      }

      return video;
    });
  }

  return const HtmlElementView(viewType: 'proctor-live-webcam-feed');
}

bool get isWebcamPlatformSupported => true;
