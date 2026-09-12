import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/knowledge_graph_model.dart';

/// Renders a dynamic, theme-harmonized card for a Knowledge Graph concept node.
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
    final colors = context.colors;

    if (node.type == NodeType.section) {
      return _buildSectionHeader(context);
    }

    final Color borderColor = isSelected
        ? colors.accentCyan
        : _getBorderColor(context, node.type, node.status);

    final double borderWidth = isSelected ? 1.5 : 1.0;

    // Determine shape hierarchy per Hallmark specifications
    final BorderRadius borderRadius = _getBorderRadius(node.type);
    final EdgeInsets padding = _getPadding(node.type);
    final Color backgroundColor = _getBackgroundColor(context, node.type);

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
                    color: colors.accentCyan.withValues(alpha: 0.25),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4.0,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            _buildTypeIcon(context),
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
                          ? colors.fgSecondary.withValues(alpha: 0.6)
                          : (node.isOptional ? colors.fgSecondary : colors.fgPrimary),
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
                      style: TextStyle(
                        color: colors.fgSecondary,
                        fontSize: 10.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (node.status == NodeStatus.completed)
              Icon(Icons.check_circle, color: colors.accentEmerald, size: 16)
            else if (node.metadata.activityType != null)
              GestureDetector(
                onTap: onLaunchActivity,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.borderSubtle, width: 0.8),
                  ),
                  child: Icon(Icons.play_arrow, color: colors.accentCyan, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: node.geometry.width,
        height: node.geometry.height,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? colors.accentCyan : colors.accentCyan.withValues(alpha: 0.7),
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.accentCyan.withValues(alpha: isSelected ? 0.25 : 0.08),
              blurRadius: 10.0,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.bookmark_outline,
              color: colors.accentCyan,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                node.label,
                style: TextStyle(
                  color: colors.fgPrimary,
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
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.borderSubtle, width: 0.8),
              ),
              child: Text(
                'Section',
                style: TextStyle(
                  color: colors.accentCyan,
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

  Color _getBackgroundColor(BuildContext context, NodeType type) {
    final colors = context.colors;
    switch (type) {
      case NodeType.reference:
      case NodeType.resource:
        return colors.bgElevated;
      case NodeType.alternative:
        return colors.bgSurface;
      case NodeType.optional:
        return colors.bgCanvas;
      default:
        return colors.bgSurface;
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

  Widget _buildTypeIcon(BuildContext context) {
    final colors = context.colors;
    IconData icon;
    Color color;

    switch (node.type) {
      case NodeType.section:
        icon = Icons.folder_open;
        color = colors.accentCyan;
      case NodeType.topic:
        icon = Icons.radio_button_checked;
        color = colors.accentCyan;
      case NodeType.subtopic:
        icon = Icons.commit;
        color = colors.fgSecondary;
      case NodeType.quiz:
        icon = Icons.quiz_outlined;
        color = const Color(0xFFC084FC);
      case NodeType.project:
        icon = Icons.code;
        color = colors.accentEmerald;
      case NodeType.assessment:
        icon = Icons.workspace_premium_outlined;
        color = const Color(0xFFF59E0B);
      case NodeType.reference:
        icon = Icons.menu_book_outlined;
        color = colors.fgSecondary;
      case NodeType.optional:
        icon = Icons.help_outline;
        color = colors.fgSecondary;
      case NodeType.alternative:
        icon = Icons.alt_route;
        color = colors.fgSecondary;
      case NodeType.resource:
        icon = Icons.link;
        color = colors.accentCyan;
    }

    return Icon(icon, size: 16, color: color);
  }

  Color _getBorderColor(BuildContext context, NodeType type, NodeStatus status) {
    final colors = context.colors;
    if (status == NodeStatus.completed) return colors.accentEmerald;
    if (status == NodeStatus.inProgress) return colors.accentCyan;

    switch (type) {
      case NodeType.section:
        return colors.accentCyan;
      case NodeType.topic:
        return colors.borderSubtle;
      case NodeType.project:
        return colors.accentEmerald.withValues(alpha: 0.6); // Emerald accent
      case NodeType.assessment:
        return const Color(0xFFF59E0B).withValues(alpha: 0.6); // Amber milestone
      case NodeType.quiz:
        return const Color(0xFF9333EA).withValues(alpha: 0.6);
      case NodeType.optional:
        return colors.borderSubtle;
      default:
        return colors.borderSubtle;
    }
  }
}
