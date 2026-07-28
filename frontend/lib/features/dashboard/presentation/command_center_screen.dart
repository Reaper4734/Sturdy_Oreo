import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../data/mock_dashboard_data.dart';
import 'widgets/greeting_hero_card.dart';
import 'widgets/continue_learning_card.dart';
import 'widgets/learning_journey_card.dart';
import 'widgets/roadmap_preview_card.dart';
import 'widgets/needs_attention_card.dart';
import 'widgets/activity_feed_card.dart';
import 'widgets/learning_consistency_widget.dart';
import 'widgets/workspace_summary_card.dart';
import 'package:frontend/features/dashboard/data/mock_dashboard_data.dart';
import 'package:frontend/features/dashboard/data/http_dashboard_repository.dart';
import 'package:frontend/features/dashboard/presentation/providers/mascot_provider.dart';

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
  final _repository = HttpDashboardRepository();
  DashboardMockProfile? _profile;
  HeatmapSummary? _heatmapSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _repository.fetchDashboardProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _heatmapSummary = MockDashboardRepository.computeHeatmapSummary(profile.heatmapScores);
        _isLoading = false;
      });
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

    final profile = _profile!;
    final greeting = MockDashboardRepository.getTimeGreeting();

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
                  return _buildDesktopLayout(profile, greeting);
                }
                return _buildMobileLayout(profile, greeting);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(DashboardMockProfile profile, String greeting) {
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
                  data: profile.continueLearning,
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

  Widget _buildMobileLayout(DashboardMockProfile profile, String greeting) {
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
          data: profile.continueLearning,
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
