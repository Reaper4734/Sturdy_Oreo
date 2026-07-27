import 'dart:async';
import 'dart:math';

class VoiceAssistantService {
  bool _isListening = false;
  bool _isSpeaking = false;
  Timer? _waveformTimer;
  final _waveformController = StreamController<List<double>>.broadcast();

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  Stream<List<double>> get waveformStream => _waveformController.stream;

  void startListening({required Function(String text) onRecognizedText}) {
    _isListening = true;
    _startWaveformSimulation();

    // Simulated speech recognition updates
    Timer(const Duration(seconds: 2), () {
      if (_isListening) {
        onRecognizedText('I want to build a real-time portfolio dashboard with Python and Flutter');
        stopListening();
      }
    });
  }

  void stopListening() {
    _isListening = false;
    _stopWaveformSimulation();
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
  }
}
