import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class WorkspaceGenerationInterstitial extends StatefulWidget {
  final VoidCallback onCompleted;
  final String topicName;

  const WorkspaceGenerationInterstitial({
    super.key,
    required this.onCompleted,
    this.topicName = 'New Subject',
  });

  @override
  State<WorkspaceGenerationInterstitial> createState() => _WorkspaceGenerationInterstitialState();
}

class _WorkspaceGenerationInterstitialState extends State<WorkspaceGenerationInterstitial> {
  int _currentStep = 0;
  Timer? _timer;

  final List<String> _steps = const [
    'Understanding your experience',
    'Building your learner profile',
    'Designing your Subject Mind Map',
    'Generating learning roadmap',
    'Preparing flashcards',
    'Configuring Learning Lab',
    'Initializing AI memory',
    'Opening workspace...',
  ];

  @override
  void initState() {
    super.initState();
    _startStepping();
  }

  void _startStepping() {
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            widget.onCompleted();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      color: colors.bgCanvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.accentEmerald),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Generating Learning Space...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.fgPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tailoring "${widget.topicName}" to your exact experience level and goals.',
                  style: TextStyle(fontSize: 13, color: colors.fgSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                Divider(height: 1, color: colors.borderSubtle),
                const SizedBox(height: 20),
                ...List.generate(_steps.length, (index) {
                  final isDone = index < _currentStep;
                  final isCurrent = index == _currentStep;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isDone
                                ? colors.accentEmerald
                                : (isCurrent ? colors.accentEmerald.withValues(alpha: 0.15) : colors.bgElevated),
                            shape: BoxShape.circle,
                            border: isCurrent
                                ? Border.all(color: colors.accentEmerald, width: 2)
                                : (isDone ? null : Border.all(color: colors.borderSubtle)),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                : (isCurrent
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colors.accentEmerald,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : const SizedBox.shrink()),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          _steps[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: isDone
                                ? colors.fgPrimary
                                : (isCurrent ? colors.accentEmerald : colors.fgSecondary.withValues(alpha: 0.7)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
