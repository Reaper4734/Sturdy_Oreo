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
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Learning Roadmap', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
              InkWell(
                onTap: onOpenFullRoadmap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Open Full Roadmap', style: TextStyle(fontSize: 13, color: AppColors.fgAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16, color: AppColors.fgAccent),
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
                children: _buildAdaptiveNodes(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAdaptiveNodes() {
    final List<Widget> children = [];
    for (int i = 0; i < nodes.length; i++) {
      children.add(_buildNode(nodes[i]));
      if (i < nodes.length - 1) {
        children.add(_buildConnector());
      }
    }
    return children;
  }

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.only(top: 14, left: 8, right: 8),
      child: SizedBox(
        width: 32,
        child: Divider(color: AppColors.borderSubtle, thickness: 2),
      ),
    );
  }

  Widget _buildNode(RoadmapPreviewNode node) {
    final Color color;
    final IconData icon;
    switch (node.status) {
      case RoadmapNodeStatus.completed:
        color = AppColors.accentEmerald;
        icon = Icons.check_circle;
      case RoadmapNodeStatus.active:
        color = AppColors.fgAccent;
        icon = Icons.play_circle_fill;
      case RoadmapNodeStatus.locked:
        color = AppColors.fgTertiary;
        icon = Icons.circle_outlined;
    }

    return Tooltip(
      message: node.title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 120, // Clamp width so it doesn't grow indefinitely
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
                color: node.status == RoadmapNodeStatus.locked ? AppColors.fgTertiary : AppColors.fgPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
