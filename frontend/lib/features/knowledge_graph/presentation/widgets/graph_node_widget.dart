import 'package:flutter/material.dart';
import '../../domain/models/knowledge_graph_model.dart';

/// Renders a minimal, sleek dark-themed card for a Knowledge Graph concept node.
/// Follows Oreo's exact color tokens: #212121 Surface, #333333 Border, #ECECEC Text, #878787 Muted.
class GraphNodeWidget extends StatelessWidget {
  final GraphNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLaunchActivity;

  const GraphNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.onTap,
    this.onLaunchActivity,
  });

  @override
  Widget build(BuildContext context) {
    if (node.type == NodeType.section) {
      return _buildSectionHeader();
    }

    final Color borderColor = isSelected
        ? const Color(0xFF67E8F9)
        : _getBorderColor(node.type, node.status);

    final double borderWidth = isSelected ? 1.5 : 1.0;

    // Determine shape hierarchy per Hallmark specifications
    final BorderRadius borderRadius = _getBorderRadius(node.type);
    final EdgeInsets padding = _getPadding(node.type);
    final Color backgroundColor = _getBackgroundColor(node.type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: node.geometry.width,
        height: node.geometry.height,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
            style: BorderStyle.solid,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF67E8F9).withValues(alpha: 0.15),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            _buildTypeIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.label,
                    style: TextStyle(
                      color: node.status == NodeStatus.skipped
                          ? const Color(0xFF878787)
                          : (node.isOptional ? const Color(0xFFB0B0B0) : const Color(0xFFECECEC)),
                      fontSize: _getFontSize(node.type),
                      fontWeight: isSelected ? FontWeight.w600 : _getFontWeight(node.type),
                      decoration: node.status == NodeStatus.skipped
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (node.description.isNotEmpty)
                    Text(
                      node.description,
                      style: const TextStyle(
                        color: Color(0xFF878787),
                        fontSize: 10.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (node.status == NodeStatus.completed)
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16)
            else if (node.metadata.activityType != null)
              GestureDetector(
                onTap: onLaunchActivity,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.play_arrow, color: Color(0xFF67E8F9), size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: node.geometry.width,
        height: node.geometry.height,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF67E8F9) : const Color(0xFF38BDF8),
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF67E8F9).withValues(alpha: isSelected ? 0.2 : 0.05),
              blurRadius: 10.0,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.bookmark_outline,
              color: Color(0xFF67E8F9),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                node.label,
                style: const TextStyle(
                  color: Color(0xFFECECEC),
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF262626),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF333333), width: 0.8),
              ),
              child: const Text(
                'Section',
                style: TextStyle(
                  color: Color(0xFF67E8F9),
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius(NodeType type) {
    switch (type) {
      case NodeType.assessment:
        return BorderRadius.circular(25.0); // Milestone style
      case NodeType.quiz:
        return BorderRadius.circular(18.0); // Compact badge
      case NodeType.subtopic:
        return BorderRadius.circular(20.0);
      case NodeType.reference:
      case NodeType.resource:
        return BorderRadius.circular(6.0); // Compact chip
      default:
        return BorderRadius.circular(10.0); // Standard card
    }
  }

  EdgeInsets _getPadding(NodeType type) {
    switch (type) {
      case NodeType.quiz:
      case NodeType.reference:
      case NodeType.resource:
      case NodeType.optional:
      case NodeType.alternative:
        return const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0);
      default:
        return const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0);
    }
  }

  Color _getBackgroundColor(NodeType type) {
    switch (type) {
      case NodeType.reference:
      case NodeType.resource:
        return const Color(0xFF141414); // Sleek darker chip
      case NodeType.alternative:
        return const Color(0xFF161616);
      case NodeType.optional:
        return const Color(0xFF1A1A1A);
      default:
        return const Color(0xFF212121);
    }
  }

  double _getFontSize(NodeType type) {
    switch (type) {
      case NodeType.topic:
        return 14.0;
      case NodeType.project:
        return 13.5;
      case NodeType.assessment:
        return 13.0;
      case NodeType.subtopic:
        return 12.0;
      case NodeType.quiz:
      case NodeType.reference:
      case NodeType.resource:
      case NodeType.optional:
      case NodeType.alternative:
        return 11.5;
      default:
        return 13.0;
    }
  }

  FontWeight _getFontWeight(NodeType type) {
    switch (type) {
      case NodeType.topic:
      case NodeType.project:
      case NodeType.assessment:
        return FontWeight.w600;
      default:
        return FontWeight.w500;
    }
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (node.type) {
      case NodeType.section:
        icon = Icons.folder_open;
        color = const Color(0xFF38BDF8);
      case NodeType.topic:
        icon = Icons.radio_button_checked;
        color = const Color(0xFF67E8F9);
      case NodeType.subtopic:
        icon = Icons.commit;
        color = const Color(0xFF878787);
      case NodeType.quiz:
        icon = Icons.quiz_outlined;
        color = const Color(0xFFC084FC);
      case NodeType.project:
        icon = Icons.code;
        color = const Color(0xFF10B981);
      case NodeType.assessment:
        icon = Icons.workspace_premium_outlined;
        color = const Color(0xFFF59E0B);
      case NodeType.reference:
        icon = Icons.menu_book_outlined;
        color = const Color(0xFF64748B);
      case NodeType.optional:
        icon = Icons.help_outline;
        color = const Color(0xFF878787);
      case NodeType.alternative:
        icon = Icons.alt_route;
        color = const Color(0xFF94A3B8);
      case NodeType.resource:
        icon = Icons.link;
        color = const Color(0xFF38BDF8);
    }

    return Icon(icon, size: 16, color: color);
  }

  Color _getBorderColor(NodeType type, NodeStatus status) {
    if (status == NodeStatus.completed) return const Color(0xFF10B981);
    if (status == NodeStatus.inProgress) return const Color(0xFF67E8F9);

    switch (type) {
      case NodeType.section:
        return const Color(0xFF38BDF8);
      case NodeType.topic:
        return const Color(0xFF383838);
      case NodeType.project:
        return const Color(0xFF10B981).withValues(alpha: 0.6); // Emerald accent
      case NodeType.assessment:
        return const Color(0xFFF59E0B).withValues(alpha: 0.6); // Amber milestone
      case NodeType.quiz:
        return const Color(0xFF9333EA).withValues(alpha: 0.6);
      case NodeType.optional:
        return const Color(0xFF2A2A2A);
      default:
        return const Color(0xFF333333);
    }
  }
}
