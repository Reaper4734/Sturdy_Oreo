import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../data/dashboard_model.dart';
import '../data/http_dashboard_repository.dart';
import 'widgets/greeting_hero_card.dart';
import 'widgets/continue_learning_card.dart';
import 'widgets/learning_journey_card.dart';
import 'widgets/roadmap_preview_card.dart';
import 'widgets/needs_attention_card.dart';
import 'widgets/activity_feed_card.dart';
import 'widgets/learning_consistency_widget.dart';
import 'widgets/workspace_summary_card.dart';
import '../../../shared/providers/workspace_providers.dart';

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
  HeatmapSummary? _heatmapSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await _dashboardRepo.fetchDashboardProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _heatmapSummary = HttpDashboardRepository.computeHeatmapSummary(profile.heatmapScores);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
      );
    }
    
    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load dashboard data.', style: TextStyle(color: AppColors.fgPrimary, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;
    final greeting = HttpDashboardRepository.getTimeGreeting();

    final activeWs = ref.watch(activeWorkspaceProvider);
    ContinueLearningData clData = profile.continueLearning;
    if (activeWs != null) {
      clData = ContinueLearningData(
        workspaceName: activeWs.title,
        currentCourse: activeWs.activeLearningContext,
        difficulty: activeWs.difficulty,
        currentTopic: activeWs.activeLearningContext,
        nextAction: 'Continue',
        estimatedTime: '30m',
        progressPercent: activeWs.roadmap.isNotEmpty ? 0.3 : 0.0,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                if (isDesktop) {
                  return _buildDesktopLayout(profile, greeting, clData);
                }
                return _buildMobileLayout(profile, greeting, clData);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(DashboardProfile profile, String greeting, ContinueLearningData clData) {
    const gap = 20.0;

    return Column(
      children: [
        // Row 1: Greeting Hero (12 cols)
        GreetingHeroCard(
          greeting: greeting,
          learnerName: profile.learnerName,
          insight: profile.greetingInsight,
        ),
        const SizedBox(height: gap),

        // Row 2: Continue Learning (6) + Learning Journey (6)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: ContinueLearningCard(
                  data: clData,
                  onContinue: widget.onNavigateToStudio,
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                flex: 4,
                child: LearningJourneyCard(data: profile.journey),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),

        // Row 3: Roadmap (7) + Needs Attention (5)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: RoadmapPreviewCard(
                  nodes: profile.roadmapNodes,
                  onOpenFullRoadmap: () {},
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                flex: 4,
                child: NeedsAttentionCard(items: profile.attentionItems),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),

        // Row 4: Timeline (5) + Portfolio (7)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: ActivityFeedCard(events: profile.timelineEvents),
              ),
              const SizedBox(width: gap),
              Expanded(
                flex: 5,
                child: WorkspaceSummaryCard(data: profile.workspaceSummary),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),

        // Row 5: Heatmap (12 cols)
        LearningConsistencyWidget(
          scores: profile.heatmapScores,
          summary: _heatmapSummary!,
        ),
      ],
    );
  }

  Widget _buildMobileLayout(DashboardProfile profile, String greeting, ContinueLearningData clData) {
    const gap = 16.0;

    return Column(
      children: [
        GreetingHeroCard(
          greeting: greeting,
          learnerName: profile.learnerName,
          insight: profile.greetingInsight,
        ),
        const SizedBox(height: gap),
        ContinueLearningCard(
          data: clData,
          onContinue: widget.onNavigateToStudio,
        ),
        const SizedBox(height: gap),
        LearningJourneyCard(data: profile.journey),
        const SizedBox(height: gap),
        RoadmapPreviewCard(nodes: profile.roadmapNodes, onOpenFullRoadmap: () {}),
        const SizedBox(height: gap),
        NeedsAttentionCard(items: profile.attentionItems),
        const SizedBox(height: gap),
        ActivityFeedCard(events: profile.timelineEvents),
        const SizedBox(height: gap),
        WorkspaceSummaryCard(data: profile.workspaceSummary),
        const SizedBox(height: gap),
        LearningConsistencyWidget(scores: profile.heatmapScores, summary: _heatmapSummary!),
      ],
    );
  }
}
