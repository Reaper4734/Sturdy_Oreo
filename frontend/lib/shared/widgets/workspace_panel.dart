import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../models/workspace_model.dart';
import '../providers/workspace_providers.dart';

/// /ponytail ceiling: Minimal "Continue Learning" project switcher.
/// Removed search filtering, filter tabs, and context menus to eliminate UI boilerplate (YAGNI).
/// Upgrade path: Re-introduce search and virtualization when user exceeds 15+ workspaces.
class WorkspacePanel extends ConsumerStatefulWidget {
  final VoidCallback onNewWorkspaceClicked;
  final VoidCallback onWorkspaceSelected;

  const WorkspacePanel({
    super.key, 
    required this.onNewWorkspaceClicked,
    required this.onWorkspaceSelected,
  });

  @override
  ConsumerState<WorkspacePanel> createState() => _WorkspacePanelState();
}

class _WorkspacePanelState extends ConsumerState<WorkspacePanel> {
  String _formatAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 5) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 14) return 'Last week';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  void _handleSelectWorkspace(WorkspaceModel ws) {
    ref.read(activeWorkspaceIdProvider.notifier).state = ws.id;
    ref.read(workspaceListProvider.notifier).touchWorkspace(ws.id);
    ref.read(workspacePanelOpenProvider.notifier).state = false;
    widget.onWorkspaceSelected();
  }

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspaceListProvider);
    final activeId = ref.watch(activeWorkspaceIdProvider);

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppColors.bgSidebar,
        border: Border(right: BorderSide(color: AppColors.borderSubtle, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(5, 0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Continue Learning',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.fgSecondary, size: 18),
                  onPressed: () => ref.read(workspacePanelOpenProvider.notifier).state = false,
                  tooltip: 'Close Panel',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // + New Learning Space
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: InkWell(
              onTap: () {
                ref.read(workspacePanelOpenProvider.notifier).state = false;
                widget.onNewWorkspaceClicked();
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: const [
                    Icon(Icons.add_rounded, color: AppColors.accentPrimary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'New Learning Space',
                      style: TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 24, color: AppColors.borderSubtle, thickness: 0.8),
          ),

          // List of Workspaces
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: workspaces.length,
              separatorBuilder: (context, index) => const Divider(
                height: 28,
                color: AppColors.borderSubtle,
                thickness: 0.5,
              ),
              itemBuilder: (context, index) {
                final ws = workspaces[index];
                final isActive = ws.id == activeId;

                return InkWell(
                  onTap: () => _handleSelectWorkspace(ws),
                  borderRadius: BorderRadius.circular(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        ws.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppColors.accentPrimary : AppColors.fgPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Subtitle: Active Context
                      Text(
                        'Active Context: ${ws.activeLearningContext}',
                        style: const TextStyle(fontSize: 12, color: AppColors.fgSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Progress: 42% Complete
                      Text(
                        '${(ws.progressPercent * 100).toInt()}% Complete',
                        style: const TextStyle(fontSize: 12, color: AppColors.fgSecondary),
                      ),
                      const SizedBox(height: 6),
                      // Footer: Time ago & Resume CTA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatAgo(ws.lastOpened),
                            style: const TextStyle(fontSize: 11, color: AppColors.fgSecondary),
                          ),
                          Text(
                            isActive ? 'Active' : 'Resume →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppColors.fgPrimary : AppColors.accentPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
