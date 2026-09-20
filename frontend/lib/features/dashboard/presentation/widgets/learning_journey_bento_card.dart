import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/mind_map_model.dart';
import '../../../../shared/models/persona_model.dart';

import '../../../../shared/models/roadmap_model.dart';

class JourneyStageItem {
  final String title;
  final String status; // 'completed', 'active', 'locked'

  const JourneyStageItem({required this.title, required this.status});
}

class LearningJourneyBentoCard extends StatelessWidget {
  final SubjectCluster? cluster;
  final List<BlueprintNode> blueprintNodes;
  final List<RoadmapNode> roadmap;
  final String activeTopic;
  final VoidCallback onViewRoadmap;

  const LearningJourneyBentoCard({
    super.key,
    this.cluster,
    this.blueprintNodes = const [],
    this.roadmap = const [],
    required this.activeTopic,
    required this.onViewRoadmap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stages = _deriveStages();

    // Determine current and next milestone labels
    String currentActiveTitle = 'Current Module';
    String nextLockedTitle = 'Next Milestone';

    for (int i = 0; i < stages.length; i++) {
      if (stages[i].status == 'active') {
        currentActiveTitle = stages[i].title;
        if (i + 1 < stages.length) {
          nextLockedTitle = stages[i + 1].title;
        }
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Title + View Roadmap Action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  size: 16,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Learning Journey',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.fgPrimary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onViewRoadmap,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.bgActivityBar,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Mind Map',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: colors.accentPrimary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stepper Row
          if (stages.isNotEmpty) ...[
            _buildStepper(context, stages, colors),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                'Generate your learning plan in the studio to visualize your path.',
                style: TextStyle(fontSize: 12, color: colors.fgSecondary),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Next Milestone Footer Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: colors.fgPrimary),
                      children: [
                        const TextSpan(
                          text: 'Next Milestone: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: 'Complete '),
                        TextSpan(
                          text: currentActiveTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                        ),
                        const TextSpan(text: ' to unlock '),
                        TextSpan(
                          text: nextLockedTitle,
                          style: TextStyle(fontWeight: FontWeight.bold, color: colors.accentPrimary),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<JourneyStageItem> _deriveStages() {
    // 1. Prefer actual course roadmap nodes if present
    if (roadmap.isNotEmpty) {
      List<JourneyStageItem> list = [];
      bool foundActive = false;

      for (int i = 0; i < roadmap.length; i++) {
        final node = roadmap[i];
        final label = node.title.replaceAll(RegExp(r'^Module \d+:\s*'), '');
        final s = node.status.toLowerCase();

        if (s == 'completed') {
          list.add(JourneyStageItem(title: label, status: 'completed'));
        } else if (!foundActive) {
          list.add(JourneyStageItem(title: label, status: 'active'));
          foundActive = true;
        } else {
          list.add(JourneyStageItem(title: label, status: 'locked'));
        }
      }
      return list.take(5).toList();
    }

    // 2. Prefer SubjectCluster child modules
    if (cluster != null && cluster!.rootNode.children.isNotEmpty) {
      final children = cluster!.rootNode.children;
      List<JourneyStageItem> list = [];
      bool foundActive = false;

      for (int i = 0; i < children.length; i++) {
        final node = children[i];
        final label = node.label.replaceAll(RegExp(r'^Module \d+:\s*'), '');

        if (node.isMastered) {
          list.add(JourneyStageItem(title: label, status: 'completed'));
        } else if (!foundActive) {
          list.add(JourneyStageItem(title: label, status: 'active'));
          foundActive = true;
        } else {
          list.add(JourneyStageItem(title: label, status: 'locked'));
        }
      }
      return list.take(5).toList();
    }

    // 2. Fallback to BlueprintNodes
    if (blueprintNodes.isNotEmpty) {
      List<JourneyStageItem> list = [];
      for (int i = 0; i < blueprintNodes.length; i++) {
        final bp = blueprintNodes[i];
        String status = 'locked';
        if (i == 0) status = 'completed';
        if (i == 1) status = 'active';
        list.add(JourneyStageItem(title: bp.title, status: status));
      }
      return list.take(5).toList();
    }

    return [
      const JourneyStageItem(title: 'Foundations', status: 'completed'),
      const JourneyStageItem(title: 'Core Principles', status: 'completed'),
      const JourneyStageItem(title: 'Deep Architecture', status: 'active'),
      const JourneyStageItem(title: 'Advanced Patterns', status: 'locked'),
      const JourneyStageItem(title: 'Capstone Project', status: 'locked'),
    ];
  }

  Widget _buildStepper(BuildContext context, List<JourneyStageItem> stages, AppColorsExtension colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(stages.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Connecting line
              final stageIndexBefore = index ~/ 2;
              final statusBefore = stages[stageIndexBefore].status;
              final isCompletedLine = statusBefore == 'completed';

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 14),
                  height: 2,
                  color: isCompletedLine
                      ? const Color(0xFF10B981) // Green connected line
                      : colors.borderSubtle,
                ),
              );
            }

            final stageIndex = index ~/ 2;
            final stage = stages[stageIndex];
            return _buildStepNode(stage, colors);
          }),
        );
      },
    );
  }

  Widget _buildStepNode(JourneyStageItem stage, AppColorsExtension colors) {
    Widget iconWidget;
    String statusLabel = 'Locked';
    Color labelColor = colors.fgSecondary;

    if (stage.status == 'completed') {
      statusLabel = 'Completed';
      labelColor = const Color(0xFF10B981);
      iconWidget = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFF10B981),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    } else if (stage.status == 'active') {
      statusLabel = 'In Progress';
      labelColor = const Color(0xFF38BDF8);
      iconWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF38BDF8), width: 2),
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF38BDF8),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      statusLabel = 'Locked';
      labelColor = colors.fgSecondary;
      iconWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.bgActivityBar,
          shape: BoxShape.circle,
          border: Border.all(color: colors.borderSubtle, width: 1.5),
        ),
        child: Icon(Icons.lock_outline_rounded, size: 14, color: colors.fgSecondary),
      );
    }

    return SizedBox(
      width: 86,
      child: Column(
        children: [
          iconWidget,
          const SizedBox(height: 8),
          Text(
            stage.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: stage.status == 'active' ? const Color(0xFF38BDF8) : colors.fgPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 10,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
