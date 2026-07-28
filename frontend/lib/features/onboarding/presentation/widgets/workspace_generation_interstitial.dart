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
    return Container(
      color: AppColors.bgCanvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Generating Learning Space...',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tailoring "${widget.topicName}" to your exact experience level and goals.',
                  style: const TextStyle(fontSize: 13, color: AppColors.fgSecondary),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.borderSubtle),
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
                                ? AppColors.accentEmerald
                                : (isCurrent ? AppColors.accentPrimary.withValues(alpha: 0.2) : AppColors.bgElevated),
                            shape: BoxShape.circle,
                            border: isCurrent ? Border.all(color: AppColors.accentPrimary, width: 2) : null,
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
                                : (isCurrent
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(color: AppColors.accentPrimary, shape: BoxShape.circle),
                                      )
                                    : const SizedBox.shrink()),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          _steps[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isDone
                                ? AppColors.fgPrimary
                                : (isCurrent ? AppColors.accentPrimary : AppColors.fgSecondary.withValues(alpha: 0.6)),
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
