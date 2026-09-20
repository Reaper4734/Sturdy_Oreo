import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../models/proctored_exam_model.dart';
import 'webcam_platform.dart';

typedef OnViolationCallback = void Function(ExamViolation violation);
typedef OnStrikeCallback = void Function(int strikeCount, String message);
typedef OnDisqualifiedCallback = void Function();

class ExamAntiCheatSentinel with WidgetsBindingObserver {
  final OnViolationCallback onViolation;
  final OnStrikeCallback onStrike;
  final OnDisqualifiedCallback onDisqualified;

  bool _isActive = false;
  int _strikeCount = 0;
  double _trustScore = 100.0;
  DateTime? _lastViolationTime;

  ExamAntiCheatSentinel({
    required this.onViolation,
    required this.onStrike,
    required this.onDisqualified,
  });

  int get strikeCount => _strikeCount;
  double get trustScore => _trustScore;
  bool get isActive => _isActive;

  void startMonitoring() {
    if (_isActive) return;
    _isActive = true;
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);

    // Register browser-level copy/paste/cut interceptor
    registerClipboardViolationHandler((type) {
      if (!_isActive) return;
      if (type == 'copy') {
        _reportShortcutViolation(
          type: ViolationType.clipboardCopy,
          title: 'Browser Copy Intercepted',
          details: 'Copying exam content via browser or context menu was intercepted and blocked.',
          penalty: 10.0,
        );
      } else if (type == 'paste') {
        _reportShortcutViolation(
          type: ViolationType.clipboardPaste,
          title: 'Browser Paste Intercepted',
          details: 'Pasting external content into the exam environment was intercepted and blocked.',
          penalty: 15.0,
        );
      } else if (type == 'cut') {
        _reportShortcutViolation(
          type: ViolationType.clipboardCopy,
          title: 'Browser Cut Intercepted',
          details: 'Cutting content from the exam was intercepted and blocked.',
          penalty: 10.0,
        );
      }
    });
  }

  void reportPasteViolation(String details) {
    if (!_isActive) return;
    _reportShortcutViolation(
      type: ViolationType.clipboardPaste,
      title: 'Clipboard Paste Intercepted',
      details: details,
      penalty: 15.0,
    );
  }

  void reportAudioAnomaly(double db) {
    if (!_isActive) return;
    _reportShortcutViolation(
      type: ViolationType.audioAnomaly,
      title: 'Acoustic Anomaly: Elevated Sound Level',
      details: 'Microphone detected background speech or conversation (${db.toStringAsFixed(1)} dB). Testing environment must remain quiet.',
      penalty: 5.0,
    );
  }

  void stopMonitoring() {
    if (!_isActive) return;
    _isActive = false;
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isActive) return;

    if (state == AppLifecycleState.inactive || 
        state == AppLifecycleState.paused || 
        state == AppLifecycleState.hidden) {
      _reportTabSwitchOrBlur(
        type: ViolationType.tabSwitch,
        title: 'Window Focus Lost / Tab Switched',
        details: 'Exam window lost focus or user switched applications/tabs.',
        penalty: 15.0,
      );
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_isActive || event is! KeyDownEvent) return false;

    final isControl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final key = event.logicalKey;

    // 1. Intercept Copy: Ctrl/Cmd + C
    if (isControl && key == LogicalKeyboardKey.keyC) {
      _reportShortcutViolation(
        type: ViolationType.clipboardCopy,
        title: 'Clipboard Copy Intercepted',
        details: 'Attempted to copy exam content to clipboard (Ctrl+C).',
        penalty: 10.0,
      );
      return true; // Block event
    }

    // 2. Intercept Paste: Ctrl/Cmd + V
    if (isControl && key == LogicalKeyboardKey.keyV) {
      _reportShortcutViolation(
        type: ViolationType.clipboardPaste,
        title: 'Clipboard Paste Intercepted',
        details: 'Attempted to paste external content into exam (Ctrl+V).',
        penalty: 10.0,
      );
      return true; // Block event
    }

    // 3. Intercept Inspect / DevTools: F12 or Ctrl+Shift+I or Ctrl+Shift+J
    if (key == LogicalKeyboardKey.f12 || 
        (isControl && isShift && (key == LogicalKeyboardKey.keyI || key == LogicalKeyboardKey.keyJ))) {
      _reportShortcutViolation(
        type: ViolationType.devtoolsOpened,
        title: 'DevTools Inspection Shortcut Intercepted',
        details: 'Attempted to inspect web element or open developer tools.',
        penalty: 20.0,
      );
      return true; // Block event
    }

    // 4. Intercept View Source: Ctrl/Cmd + U
    if (isControl && key == LogicalKeyboardKey.keyU) {
      _reportShortcutViolation(
        type: ViolationType.shortcutViolation,
        title: 'Source View Shortcut Intercepted',
        details: 'Attempted to view page source code.',
        penalty: 15.0,
      );
      return true; // Block event
    }

    return false;
  }

  void _reportTabSwitchOrBlur({
    required ViolationType type,
    required String title,
    required String details,
    required double penalty,
  }) {
    // Debounce rapid successive blur triggers within 1.5 seconds
    final now = DateTime.now();
    if (_lastViolationTime != null && now.difference(_lastViolationTime!).inMilliseconds < 1500) {
      return;
    }
    _lastViolationTime = now;

    _strikeCount++;
    _trustScore = (_trustScore - penalty).clamp(0.0, 100.0);

    final violation = ExamViolation(
      timestamp: now,
      type: type,
      title: title,
      details: details,
      trustPenalty: penalty,
    );

    onViolation(violation);

    if (_strikeCount >= 3) {
      onDisqualified();
    } else {
      onStrike(_strikeCount, 'Warning ($_strikeCount/3): Leaving or unfocusing the exam window is strictly recorded.');
    }
  }

  void _reportShortcutViolation({
    required ViolationType type,
    required String title,
    required String details,
    required double penalty,
  }) {
    final now = DateTime.now();
    _trustScore = (_trustScore - penalty).clamp(0.0, 100.0);

    final violation = ExamViolation(
      timestamp: now,
      type: type,
      title: title,
      details: details,
      trustPenalty: penalty,
    );

    onViolation(violation);
  }

  void dispose() {
    stopMonitoring();
  }
}
