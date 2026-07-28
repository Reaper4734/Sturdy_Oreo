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
    return Container(
      color: AppColors.bgCanvas,
      padding: EdgeInsets.all(widget.isCompact ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isCompact) ...[
            Row(
              children: const [
                Icon(Icons.menu_book_rounded, color: AppColors.fgAccent, size: 22),
                SizedBox(width: 10),
                Text(
                  'Curriculum Navigator',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'What can I learn next? Select any activity below to jump straight into the interactive Learning Lab.',
              style: TextStyle(fontSize: 13, color: AppColors.fgSecondary),
            ),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: widget.roadmap.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.roadmap.length,
                    itemBuilder: (context, index) {
                      final week = widget.roadmap[index];
                      return _buildWeekCard(week);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_stories_outlined, size: 48, color: AppColors.fgSecondary),
          SizedBox(height: 12),
          Text(
            'No Curriculum Available',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
          ),
          SizedBox(height: 6),
          Text(
            'Generate a personalized roadmap to begin learning.',
            style: TextStyle(fontSize: 13, color: AppColors.fgSecondary),
          ),
        ],
      ),
    );
  }

  /// Level 1: Week Card
  Widget _buildWeekCard(RoadmapNode week) {
    final progressInt = (week.progressPercent * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
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
              hoverColor: AppColors.bgElevated,
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
                            color: AppColors.fgAccent,
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
                          color: AppColors.fgPrimary,
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
                            backgroundColor: AppColors.bgElevated,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.fgAccent),
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
                        color: AppColors.fgSecondary,
                      ),
                    ),
                    SizedBox(width: widget.isCompact ? 6 : 14),
                    Icon(
                      week.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      color: AppColors.fgSecondary,
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
                    children: week.children.map((day) => _buildDaySection(day)).toList(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Level 2: Day Section
  Widget _buildDaySection(RoadmapNode day) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.bgSidebar,
            child: InkWell(
              onTap: () {
                setState(() {
                  day.isExpanded = !day.isExpanded;
                });
                widget.onSelectNode(day.title);
                widget.onLaunchInLab?.call(day.title);
              },
              hoverColor: AppColors.bgElevated,
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
                        color: AppColors.accentEmerald,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const Spacer(),
                    if (day.estimatedTime != null) ...[
                      Text(
                        widget.isCompact ? day.estimatedTime! : 'Estimated ${day.estimatedTime}',
                        style: TextStyle(
                          fontSize: widget.isCompact ? 11 : 12,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                      SizedBox(width: widget.isCompact ? 6 : 12),
                    ],
                    Icon(
                      day.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      color: AppColors.fgSecondary,
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
                      children: day.children.map((activity) => _buildActivityRow(activity)).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Level 3: Activity Row
  Widget _buildActivityRow(RoadmapNode activity) {
    final completed = _isCompleted(activity);
    final inProgress = !completed && _isInProgress(activity);

    final bgColor = completed
        ? AppColors.bgSidebar
        : (inProgress
            ? Color.alphaBlend(AppColors.fgAccent.withValues(alpha: 0.08), AppColors.bgSurface)
            : AppColors.bgSurface);

    final borderColor = inProgress ? AppColors.fgAccent : AppColors.borderSubtle;

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
              hoverColor: AppColors.bgElevated,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCompact ? 10 : 16,
                  vertical: widget.isCompact ? 8 : 12,
                ),
                child: Row(
                  children: [
                    if (completed)
                      Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: widget.isCompact ? 16 : 18)
                    else
                      Icon(_getActivityIcon(activity.activityType), color: inProgress ? AppColors.fgPrimary : AppColors.fgSecondary, size: widget.isCompact ? 16 : 18),
                    SizedBox(width: widget.isCompact ? 8 : 14),
                    Expanded(
                      child: Text(
                        activity.title,
                        style: TextStyle(
                          fontSize: widget.isCompact ? 12 : 14,
                          fontWeight: inProgress ? FontWeight.bold : FontWeight.w500,
                          color: AppColors.accentEmerald,
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
                          color: AppColors.fgSecondary,
                        ),
                      ),
                      SizedBox(width: widget.isCompact ? 4 : 12),
                    ],
                    Icon(
                      activity.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      size: widget.isCompact ? 12 : 14,
                      color: AppColors.fgSecondary,
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
                      _buildModalityOption(Icons.play_circle_outline_rounded, 'Watch Video', activity),
                      _buildModalityOption(Icons.article_outlined, 'Read Article', activity),
                      _buildModalityOption(Icons.code_rounded, 'Practice Lab', activity),
                      _buildModalityOption(Icons.quiz_outlined, 'Take Quiz', activity),
                      _buildFlashcardOption(Icons.style_outlined, 'Generate Flashcards', activity),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFlashcardOption(IconData icon, String title, RoadmapNode activity) {
    return InkWell(
      onTap: () {
        widget.onGenerateFlashcards?.call(activity.title);
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accentEmerald),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.fgPrimary, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accentEmerald),
          ],
        ),
      ),
    );
  }

  Widget _buildModalityOption(IconData icon, String title, RoadmapNode activity) {
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
            Icon(icon, size: 16, color: AppColors.fgAccent),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.fgPrimary),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.fgSecondary),
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
