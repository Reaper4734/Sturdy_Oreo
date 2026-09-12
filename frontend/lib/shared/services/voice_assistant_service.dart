import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceAssistantService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  Timer? _waveformTimer;
  final _waveformController = StreamController<List<double>>.broadcast();

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  Stream<List<double>> get waveformStream => _waveformController.stream;

  Future<void> startListening({required Function(String text) onRecognizedText}) async {
    _isListening = true;
    _startWaveformSimulation();

    try {
      if (!_isInitialized) {
        _isInitialized = await _speech.initialize(
          onError: (val) {
            debugPrint('Speech recognition error: $val');
            stopListening();
          },
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
              _stopWaveformSimulation();
            }
          },
        );
      }

      if (_isInitialized) {
        await _speech.listen(
          onResult: (val) {
            if (val.recognizedWords.isNotEmpty) {
              onRecognizedText(val.recognizedWords);
            }
          },
        );
      } else {
        debugPrint('Speech recognition not available on this device');
      }
    } catch (e) {
      debugPrint('Speech recognition initialization failed: $e');
      stopListening();
    }
  }

  void stopListening() {
    _isListening = false;
    _stopWaveformSimulation();
    try {
      _speech.stop();
    } catch (_) {}
  }

  void startSpeaking(String text) {
    _isSpeaking = true;
    _startWaveformSimulation();

    Timer(const Duration(seconds: 4), () {
      _isSpeaking = false;
      _stopWaveformSimulation();
    });
  }

  void _startWaveformSimulation() {
    _waveformTimer?.cancel();
    final random = Random();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      final bars = List.generate(24, (_) => 0.15 + random.nextDouble() * 0.85);
      _waveformController.add(bars);
    });
  }

  void _stopWaveformSimulation() {
    _waveformTimer?.cancel();
    final silentBars = List.generate(24, (_) => 0.15);
    _waveformController.add(silentBars);
  }

  void dispose() {
    _waveformTimer?.cancel();
    _waveformController.close();
    try {
      _speech.stop();
    } catch (_) {}
  }
}
