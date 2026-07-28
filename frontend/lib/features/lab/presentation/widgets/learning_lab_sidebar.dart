import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../workspace/data/http_workspace_repository.dart';
import '../../../../shared/models/flashcard_model.dart';
import '../../../../shared/providers/workspace_providers.dart';
import '../../../onboarding/presentation/micro_interview_screen.dart';
import '../../../roadmap/presentation/roadmap_explorer_widget.dart';

/// Learning Lab Dual Panel System (Version 1.0).
/// Introduces a dual-panel sidebar allowing instant switching between:
/// 1. Oreo AI Assistant (Default)
/// 2. Course Roadmap Navigator
/// without leaving the current Learning Lab workspace.
class LearningLabSidebar extends ConsumerStatefulWidget {
  final VoidCallback? onInterviewComplete;
  final ValueChanged<String>? onSelectNode;
  final ValueChanged<FlashcardItem>? onAcceptCard;

  const LearningLabSidebar({
    super.key,
    this.onInterviewComplete,
    this.onSelectNode,
    this.onAcceptCard,
  });

  @override
  ConsumerState<LearningLabSidebar> createState() => _LearningLabSidebarState();
}

class _LearningLabSidebarState extends ConsumerState<LearningLabSidebar> {
  // 0 = Oreo AI, 1 = Roadmap (default)
  int _selectedTabIndex = 1;

  @override
  Widget build(BuildContext context) {
    final activeWs = ref.watch(activeWorkspaceProvider);
    final currentContext = activeWs?.activeLearningContext ?? 'Heap Memory';
    final currentRoadmap = activeWs?.roadmap ?? [];

    return Container(
      color: AppColors.bgSidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar Header (Oreo AI | Roadmap)
          _buildSidebarHeader(currentContext),

          // Sidebar Body (Selected View with IndexedStack to preserve state & scroll)
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                // Tab 0: Oreo AI Assistant
                DragTarget<FlashcardItem>(
                  onAcceptWithDetails: (details) {
                    if (widget.onAcceptCard != null) {
                      widget.onAcceptCard!(details.data);
                    } else {
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return MicroInterviewScreen(
                      onInterviewComplete: widget.onInterviewComplete ?? () {},
                      showHeader: false,
                    );
                  },
                ),

                // Tab 1: Lightweight Learning Roadmap Navigator
                RoadmapExplorerWidget(
                  roadmap: currentRoadmap,
                  activeLearningContext: currentContext,
                  isCompact: true,
                  onSelectNode: (nodeTitle) {
                    if (activeWs != null) {
                      ref.read(workspaceListProvider.notifier).updateActiveLearningContext(activeWs.id, nodeTitle);
                    }
                    widget.onSelectNode?.call(nodeTitle);
                  },
                  onLaunchInLab: (nodeTitle) {
                    if (activeWs != null) {
                      ref.read(workspaceListProvider.notifier).updateActiveTab(activeWs.id, 'lab');
                    }
                  },
                  onGenerateFlashcards: (subtopic) async {
                    if (activeWs != null) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(SnackBar(content: Text('Generating flashcards for $subtopic...')));
                      final newCards = await ref.read(httpWorkspaceRepositoryProvider).generateFlashcardsForTopic(subtopic);
                      if (newCards.isNotEmpty && mounted) {
                        setState(() {
                          activeWs.flashcards.addAll(newCards);
                          activeWs.flashcardCount = activeWs.flashcards.length;
                        });
                        await ref.read(workspaceListProvider.notifier).updateWorkspace(activeWs);
                        messenger.showSnackBar(const SnackBar(content: Text('Flashcards generated!')));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(String activeContext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.bgActivityBar,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          _buildTabButton(0, 'Oreo AI', Icons.auto_awesome_rounded),
          const SizedBox(width: 8),
          _buildTabButton(1, 'Roadmap', Icons.account_tree_outlined),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.bgSurface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.fgAccent : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? AppColors.fgAccent : AppColors.fgSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.fgPrimary : AppColors.fgSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
