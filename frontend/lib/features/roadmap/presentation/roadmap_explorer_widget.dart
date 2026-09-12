import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/roadmap_model.dart';

/// Roadmap-Centric Learning Architecture Explorer (Version 3.0).
/// Models a modern learning curriculum inspired by Udemy, Coursera, roadmap.sh, and VS Code Explorer.
/// Serves as the curriculum navigator answering: "What can I learn next?"
class RoadmapExplorerWidget extends StatefulWidget {
  final List<RoadmapNode> roadmap;
  final String activeLearningContext;
  final ValueChanged<String> onSelectNode;
  final ValueChanged<String>? onLaunchInLab;
  final ValueChanged<String>? onGenerateFlashcards;
  final bool isCompact;

  const RoadmapExplorerWidget({
    super.key,
    required this.roadmap,
    required this.activeLearningContext,
    required this.onSelectNode,
    this.onLaunchInLab,
    this.onGenerateFlashcards,
    this.isCompact = false,
  });

  @override
  State<RoadmapExplorerWidget> createState() => _RoadmapExplorerWidgetState();
}

class _RoadmapExplorerWidgetState extends State<RoadmapExplorerWidget> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.bgCanvas,
      padding: EdgeInsets.all(widget.isCompact ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isCompact) ...[
            Row(
              children: [
                Icon(Icons.menu_book_rounded, color: colors.fgAccent, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Curriculum Navigator',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'What can I learn next? Select any activity below to jump straight into the interactive Learning Lab.',
              style: TextStyle(fontSize: 13, color: colors.fgSecondary),
            ),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: widget.roadmap.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.roadmap.length,
                    itemBuilder: (context, index) {
                      final week = widget.roadmap[index];
                      return _buildWeekCard(context, week);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories_outlined, size: 48, color: colors.fgSecondary),
          const SizedBox(height: 12),
          Text(
            'No Curriculum Available',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.fgPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Generate a personalized roadmap to begin learning.',
            style: TextStyle(fontSize: 13, color: colors.fgSecondary),
          ),
        ],
      ),
    );
  }

  /// Level 1: Week Card
  Widget _buildWeekCard(BuildContext context, RoadmapNode week) {
    final colors = context.colors;
    final progressInt = (week.progressPercent * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Week Header (Clickable to Expand / Collapse)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  week.isExpanded = !week.isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              hoverColor: colors.bgElevated,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCompact ? 12 : 20,
                  vertical: widget.isCompact ? 12 : 16,
                ),
                child: Row(
                  children: [
                    if (week.subtitle != null && week.subtitle!.isNotEmpty) ...[
                      Expanded(
                        flex: 3,
                        child: Text(
                          week.subtitle!,
                          style: TextStyle(
                            fontSize: widget.isCompact ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            color: colors.fgAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: widget.isCompact ? 8 : 16),
                    ],
                    Expanded(
                      flex: 2,
                      child: Text(
                        week.title,
                        style: TextStyle(
                          fontSize: widget.isCompact ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: colors.fgPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.isCompact) ...[
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: week.progressPercent,
                            backgroundColor: colors.bgSecondary,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.fgAccent),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(width: widget.isCompact ? 6 : 10),
                    Text(
                      '$progressInt%',
                      style: TextStyle(
                        fontSize: widget.isCompact ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        color: colors.fgSecondary,
                      ),
                    ),
                    SizedBox(width: widget.isCompact ? 6 : 14),
                    Icon(
                      week.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      color: colors.fgSecondary,
                      size: widget.isCompact ? 16 : 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Collapsible Days Section
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: week.isExpanded && week.children.isNotEmpty
                ? Column(
                    children: week.children.map((day) => _buildDaySection(context, day)).toList(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Level 2: Day Section
  Widget _buildDaySection(BuildContext context, RoadmapNode day) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: colors.bgSidebar,
            child: InkWell(
              onTap: () {
                setState(() {
                  day.isExpanded = !day.isExpanded;
                });
                widget.onSelectNode(day.title);
                widget.onLaunchInLab?.call(day.title);
              },
              hoverColor: colors.bgElevated,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCompact ? 12 : 20,
                  vertical: widget.isCompact ? 8 : 12,
                ),
                child: Row(
                  children: [
                    Text(
                      day.title,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: colors.accentEmerald,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const Spacer(),
                    if (day.estimatedTime != null) ...[
                      Text(
                        widget.isCompact ? day.estimatedTime! : 'Estimated ${day.estimatedTime}',
                        style: TextStyle(
                          fontSize: widget.isCompact ? 11 : 12,
                          color: colors.fgSecondary,
                        ),
                      ),
                      SizedBox(width: widget.isCompact ? 6 : 12),
                    ],
                    Icon(
                      day.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      color: colors.fgSecondary,
                      size: widget.isCompact ? 16 : 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: day.isExpanded && day.children.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Column(
                      children: day.children.map((activity) => _buildActivityRow(context, activity)).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Level 3: Activity Row
  Widget _buildActivityRow(BuildContext context, RoadmapNode activity) {
    final colors = context.colors;
    final completed = _isCompleted(activity);
    final inProgress = !completed && _isInProgress(activity);

    final bgColor = completed
        ? colors.bgSidebar
        : (inProgress
            ? Color.alphaBlend(colors.fgAccent.withValues(alpha: 0.08), colors.bgSurface)
            : colors.bgSurface);

    final borderColor = inProgress ? colors.fgAccent : colors.borderSubtle;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 8 : 20,
            vertical: widget.isCompact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: inProgress ? 1.5 : 1.0),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.onSelectNode(activity.title);
                widget.onLaunchInLab?.call(activity.title);
              },
              borderRadius: BorderRadius.circular(8),
              hoverColor: colors.bgElevated,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCompact ? 10 : 16,
                  vertical: widget.isCompact ? 8 : 12,
                ),
                child: Row(
                  children: [
                    if (completed)
                      Icon(Icons.check_circle_rounded, color: colors.accentEmerald, size: widget.isCompact ? 16 : 18)
                    else
                      Icon(_getActivityIcon(activity.activityType), color: inProgress ? colors.fgPrimary : colors.fgSecondary, size: widget.isCompact ? 16 : 18),
                    SizedBox(width: widget.isCompact ? 8 : 14),
                    Expanded(
                      child: Text(
                        activity.title,
                        style: TextStyle(
                          fontSize: widget.isCompact ? 12 : 14,
                          fontWeight: inProgress ? FontWeight.bold : FontWeight.w500,
                          color: colors.accentEmerald,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: widget.isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (activity.estimatedTime != null) ...[
                      Text(
                        activity.estimatedTime!,
                        style: TextStyle(
                          fontSize: widget.isCompact ? 11 : 12,
                          color: colors.fgSecondary,
                        ),
                      ),
                      SizedBox(width: widget.isCompact ? 4 : 12),
                    ],
                    Icon(
                      activity.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      size: widget.isCompact ? 12 : 14,
                      color: colors.fgSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: activity.isExpanded
              ? Padding(
                  padding: EdgeInsets.only(
                    left: widget.isCompact ? 32 : 54,
                    right: widget.isCompact ? 8 : 20,
                    bottom: 8,
                  ),
                  child: Column(
                    children: [
                      _buildModalityOption(context, Icons.play_circle_outline_rounded, 'Watch Video', activity),
                      _buildModalityOption(context, Icons.article_outlined, 'Read Article', activity),
                      _buildModalityOption(context, Icons.code_rounded, 'Practice Lab', activity),
                      _buildModalityOption(context, Icons.quiz_outlined, 'Take Quiz', activity),
                      _buildFlashcardOption(context, Icons.style_outlined, 'Generate Flashcards', activity),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFlashcardOption(BuildContext context, IconData icon, String title, RoadmapNode activity) {
    final colors = context.colors;
    return InkWell(
      onTap: () {
        widget.onGenerateFlashcards?.call(activity.title);
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colors.accentEmerald),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: colors.fgPrimary, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.bolt_rounded, size: 14, color: colors.accentEmerald),
          ],
        ),
      ),
    );
  }

  Widget _buildModalityOption(BuildContext context, IconData icon, String title, RoadmapNode activity) {
    final colors = context.colors;
    return InkWell(
      onTap: () {
        widget.onSelectNode(activity.title);
        widget.onLaunchInLab?.call(activity.title);
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colors.fgAccent),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: colors.fgPrimary),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: colors.fgSecondary),
          ],
        ),
      ),
    );
  }

  bool _isCompleted(RoadmapNode activity) {
    return activity.status == 'Completed' || activity.status == 'Mastered';
  }

  bool _isInProgress(RoadmapNode activity) {
    return activity.status == 'In Progress' ||
           activity.status == 'Current Focus' ||
           activity.title.toLowerCase() == widget.activeLearningContext.toLowerCase() ||
           activity.isSelected;
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'Micro Quiz':
        return Icons.help_outline_rounded;
      case 'Coding Exercise':
        return Icons.terminal_rounded;
      case 'Mini Project':
        return Icons.folder_outlined;
      case 'Capstone Project':
        return Icons.folder_special_outlined;
      case 'Interview Challenge':
        return Icons.work_outline_rounded;
      case 'Mastery Assessment':
        return Icons.assignment_outlined;
      case 'Learning Topic':
      default:
        return Icons.description_outlined;
    }
  }
}
