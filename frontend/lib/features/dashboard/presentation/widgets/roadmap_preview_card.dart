import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_model.dart';

class RoadmapPreviewCard extends StatelessWidget {
  final List<RoadmapPreviewNode> nodes;
  final VoidCallback onOpenFullRoadmap;

  const RoadmapPreviewCard({
    super.key,
    required this.nodes,
    required this.onOpenFullRoadmap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: AppSpacing.pXl,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: AppRadius.rXl,
        border: Border.all(color: colors.borderSubtle, width: 1),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Learning Roadmap', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
              InkWell(
                onTap: onOpenFullRoadmap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Open Full Roadmap', style: TextStyle(fontSize: 13, color: colors.fgAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16, color: colors.fgAccent),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Adaptive horizontal scroll
          SizedBox(
            height: 90,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildAdaptiveNodes(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAdaptiveNodes(BuildContext context) {
    final List<Widget> children = [];
    for (int i = 0; i < nodes.length; i++) {
      children.add(_buildNode(context, nodes[i]));
      if (i < nodes.length - 1) {
        children.add(_buildConnector(context));
      }
    }
    return children;
  }

  Widget _buildConnector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, left: 8, right: 8),
      child: SizedBox(
        width: 32,
        child: Divider(color: context.colors.borderSubtle, thickness: 2),
      ),
    );
  }

  Widget _buildNode(BuildContext context, RoadmapPreviewNode node) {
    final colors = context.colors;
    final Color color;
    final IconData icon;
    switch (node.status) {
      case RoadmapNodeStatus.completed:
        color = colors.accentEmerald;
        icon = Icons.check_circle;
      case RoadmapNodeStatus.active:
        color = colors.fgAccent;
        icon = Icons.play_circle_fill;
      case RoadmapNodeStatus.locked:
        color = colors.fgTertiary;
        icon = Icons.circle_outlined;
    }

    return Tooltip(
      message: node.title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 120,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              node.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: node.status == RoadmapNodeStatus.active ? FontWeight.bold : FontWeight.normal,
                color: node.status == RoadmapNodeStatus.locked ? colors.fgTertiary : colors.fgPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
