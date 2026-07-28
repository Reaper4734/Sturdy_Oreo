import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../data/course_catalog_model.dart';
import '../../knowledge_graph/presentation/knowledge_graph_screen.dart';
import '../../roadmap/presentation/roadmap_explorer_widget.dart';
import '../../../shared/models/roadmap_model.dart';
import '../../workspace/data/http_workspace_repository.dart';
import '../../../shared/providers/workspace_providers.dart';


class CoursePreviewScreen extends ConsumerStatefulWidget {
  final CourseCatalogEntry course;
  final VoidCallback onNavigateToWorkspace;

  const CoursePreviewScreen({
    super.key,
    required this.course,
    required this.onNavigateToWorkspace,
  });

  @override
  ConsumerState<CoursePreviewScreen> createState() => _CoursePreviewScreenState();
}

class _CoursePreviewScreenState extends ConsumerState<CoursePreviewScreen> {
  String _activeTab = 'mind_map'; // 'mind_map' or 'roadmap'
  bool _isGenerating = false;

  Future<void> _moveToWorkspace() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final repo = ref.read(httpWorkspaceRepositoryProvider);
      final newWs = await repo.createWorkspaceFromCourse(widget.course.title);
      
      ref.read(workspaceListProvider.notifier).createWorkspace(newWs);
      ref.read(activeWorkspaceIdProvider.notifier).state = newWs.id;
      widget.onNavigateToWorkspace();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate workspace: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        children: [
          // Header Bar
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: AppColors.bgActivityBar,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.fgPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back to Knowledge Hub',
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.course.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.fgPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Course Preview',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Segmented Control (Centered if possible, but keeping it simple here)
                _buildSegmentedSwitch(),
                const Spacer(),
                // Start Learning Button
                _isGenerating
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: AppColors.accentPrimary),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _moveToWorkspace,
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Move to Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPrimary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              ],
            ),
          ),
          
          // Content Area
          Expanded(
            child: _activeTab == 'mind_map' ? _buildMindMap() : _buildRoadmap(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton('mind_map', 'Mind Map', Icons.account_tree_outlined),
          _buildTabButton('roadmap', 'Roadmap', Icons.format_list_bulleted_rounded),
        ],
      ),
    );
  }

  Widget _buildTabButton(String id, String label, IconData icon) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.bgElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? AppColors.fgPrimary : AppColors.fgSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.fgPrimary : AppColors.fgSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMindMap() {
    // Reuse the existing KnowledgeGraphScreen with read-only callbacks
    return KnowledgeGraphScreen(
      initialWorkspaceId: widget.course.id,
      onNodeSelected: (_) {}, // Read-only
      onLaunchLearningLab: (_) {}, // Read-only
    );
  }

  Widget _buildRoadmap() {
    // Generate a naive preview roadmap from course tags
    final roadmapNodes = widget.course.tags.map((tag) => RoadmapNode(
          id: tag.replaceAll(' ', '_'),
          title: tag,
          subtitle: 'Module',
          status: 'Not Started',
        )).toList();

    return RoadmapExplorerWidget(
      roadmap: roadmapNodes,
      activeLearningContext: '',
      onSelectNode: (_) {}, // Read-only
      isCompact: false,
    );
  }
}

