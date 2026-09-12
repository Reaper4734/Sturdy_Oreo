import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/providers/workspace_providers.dart';
import '../data/dashboard_model.dart';
import '../data/http_dashboard_repository.dart';
import 'widgets/dashboard_header_widget.dart';
import 'widgets/continue_learning_bento_card.dart';
import 'widgets/todays_focus_bento_card.dart';
import 'widgets/learning_journey_bento_card.dart';
import 'widgets/next_up_bento_card.dart';
import 'widgets/gamification_bento_row.dart';
import 'widgets/dashboard_encouragement_banner.dart';

class CommandCenterScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToStudio;

  const CommandCenterScreen({
    super.key,
    required this.onNavigateToStudio,
  });

  @override
  ConsumerState<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen> {
  final HttpDashboardRepository _dashboardRepo = HttpDashboardRepository();
  DashboardProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeWsId = ref.read(activeWorkspaceIdProvider);
      _loadData(workspaceId: activeWsId);
    });
  }

  Future<void> _loadData({String? workspaceId}) async {
    try {
      final profile = await _dashboardRepo.fetchDashboardProfile(workspaceId: workspaceId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeWs = ref.watch(activeWorkspaceProvider);
    final workspaceList = ref.watch(workspaceListProvider);

    // Listen for workspace switches to reload profile seamlessly
    ref.listen<String?>(activeWorkspaceIdProvider, (previous, next) {
      if (previous != next) {
        _loadData(workspaceId: next);
      }
    });

    if (_isLoading && activeWs == null && workspaceList.isEmpty) {
      return Scaffold(
        backgroundColor: colors.bgCanvas,
        body: Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
      );
    }

    // Determine learner name
    final learnerName = _profile?.learnerName.isNotEmpty == true ? _profile!.learnerName : 'Priyaj';

    // If there are no workspaces at all, show clean onboarding state
    if (workspaceList.isEmpty && activeWs == null) {
      return _buildEmptyWorkspaceView(context, learnerName, colors);
    }

    // Compute metrics from active workspace
    final currentWs = activeWs ?? workspaceList.first;
    final subject = currentWs.subject.isNotEmpty ? currentWs.subject : currentWs.title;
    final currentTopic = currentWs.activeLearningContext.isNotEmpty
        ? currentWs.activeLearningContext
        : 'Core Fundamentals';

    // Compute concept counts from SubjectCluster
    int masteredConcepts = 0;
    int totalConcepts = 0;
    List<String> focusTags = [];
    String nextModuleTitle = 'Advanced Applications';
    String nextModuleDesc = 'Explore deeper patterns and practical integrations.';

    if (currentWs.subjectCluster != null) {
      final root = currentWs.subjectCluster!.rootNode;
      for (final module in root.children) {
        totalConcepts++;
        if (module.isMastered) {
          masteredConcepts++;
        }
        for (final topic in module.children) {
          totalConcepts++;
          if (topic.isMastered) {
            masteredConcepts++;
          }
          if (focusTags.length < 4) {
            focusTags.add(topic.label);
          }
        }
      }

      // Find next unlocked/upcoming module
      final upcomingModules = root.children.where((m) => !m.isMastered).toList();
      if (upcomingModules.length > 1) {
        nextModuleTitle = upcomingModules[1].label.replaceAll(RegExp(r'^Module \d+:\s*'), '');
        if (upcomingModules[1].children.isNotEmpty) {
          nextModuleDesc = upcomingModules[1].children.map((c) => c.label).take(3).join(', ');
        }
      } else if (upcomingModules.isNotEmpty) {
        nextModuleTitle = upcomingModules[0].label.replaceAll(RegExp(r'^Module \d+:\s*'), '');
        if (upcomingModules[0].children.isNotEmpty) {
          nextModuleDesc = upcomingModules[0].children.map((c) => c.label).take(3).join(', ');
        }
      }
    }

    // Fallback focus tags from Blueprint
    if (focusTags.isEmpty && currentWs.persona != null && currentWs.persona!.blueprintNodes.isNotEmpty) {
      focusTags = currentWs.persona!.blueprintNodes.first.topics;
    }

    final double progress = totalConcepts > 0
        ? (masteredConcepts / totalConcepts).clamp(0.0, 1.0)
        : (currentWs.progressPercent > 0 ? currentWs.progressPercent : 0.45);

    final int streak = _profile?.journey.streakDays ?? 7;
    final int completedSessions = masteredConcepts > 0 ? masteredConcepts : 4;
    final int weeklyTarget = 5;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                DashboardHeaderWidget(
                  learnerName: learnerName,
                  streakDays: streak,
                  completedSessions: completedSessions,
                  weeklyTarget: weeklyTarget,
                  onNotificationTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications')),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 2. Bento Row 1: Continue Learning (~58%) | Today's Focus (~42%)
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 960) {
                      return Column(
                        children: [
                          ContinueLearningBentoCard(
                            subject: subject,
                            currentTopic: currentTopic,
                            progressPercent: progress,
                            completedNodes: masteredConcepts > 0 ? masteredConcepts : 3,
                            totalNodes: totalConcepts > 0 ? totalConcepts : 5,
                            estimatedMinutesRemaining: 28,
                            onContinue: widget.onNavigateToStudio,
                          ),
                          const SizedBox(height: 16),
                          TodaysFocusBentoCard(
                            focusTopic: subject,
                            estimatedMinutes: 35,
                            sessionProgress: 0.70,
                            focusTags: focusTags,
                            onStartSession: widget.onNavigateToStudio,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 58,
                          child: ContinueLearningBentoCard(
                            subject: subject,
                            currentTopic: currentTopic,
                            progressPercent: progress,
                            completedNodes: masteredConcepts > 0 ? masteredConcepts : 3,
                            totalNodes: totalConcepts > 0 ? totalConcepts : 5,
                            estimatedMinutesRemaining: 28,
                            onContinue: widget.onNavigateToStudio,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 42,
                          child: TodaysFocusBentoCard(
                            focusTopic: subject,
                            estimatedMinutes: 35,
                            sessionProgress: 0.70,
                            focusTags: focusTags,
                            onStartSession: widget.onNavigateToStudio,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 3. Bento Row 2: Learning Journey (~62%) | Next Up (~38%)
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 960) {
                      return Column(
                        children: [
                          LearningJourneyBentoCard(
                            cluster: currentWs.subjectCluster,
                            blueprintNodes: currentWs.persona?.blueprintNodes ?? [],
                            activeTopic: currentTopic,
                            onViewRoadmap: widget.onNavigateToStudio,
                          ),
                          const SizedBox(height: 16),
                          NextUpBentoCard(
                            nextModuleTitle: nextModuleTitle,
                            nextModuleDescription: nextModuleDesc,
                            conceptsNeededToUnlock: 2,
                            onPreview: widget.onNavigateToStudio,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 62,
                          child: LearningJourneyBentoCard(
                            cluster: currentWs.subjectCluster,
                            blueprintNodes: currentWs.persona?.blueprintNodes ?? [],
                            activeTopic: currentTopic,
                            onViewRoadmap: widget.onNavigateToStudio,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 38,
                          child: NextUpBentoCard(
                            nextModuleTitle: nextModuleTitle,
                            nextModuleDescription: nextModuleDesc,
                            conceptsNeededToUnlock: 2,
                            onPreview: widget.onNavigateToStudio,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 4. Bento Row 3: Real Data-Driven Gamification Cards
                GamificationBentoRow(
                  streakDays: streak,
                  completedSessions: completedSessions,
                  weeklyTarget: weeklyTarget,
                  masteredConcepts: masteredConcepts > 0 ? masteredConcepts : 10,
                  totalConcepts: totalConcepts > 0 ? totalConcepts : 15,
                  flashcardCount: currentWs.flashcardCount,
                  persona: currentWs.persona,
                ),
                const SizedBox(height: 16),

                // 5. Footer Encouragement Banner
                DashboardEncouragementBanner(
                  learnerName: learnerName,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWorkspaceView(BuildContext context, String learnerName, AppColorsExtension colors) {
    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, size: 36, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome, $learnerName!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Start your personalized learning journey by creating your first learning space.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.fgSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onNavigateToStudio,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Start Micro-Interview', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
