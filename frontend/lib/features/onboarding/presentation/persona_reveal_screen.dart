import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../../shared/models/learning_lab_model.dart';
import '../../../shared/models/mind_map_model.dart';
import '../../../shared/models/persona_model.dart';
import '../../../shared/providers/workspace_providers.dart';
import '../../../shared/widgets/top_tab_bar_widget.dart';
import '../../lab/presentation/learning_lab_workspace_screen.dart';
import '../../lab/presentation/widgets/flashcard_canvas_widget.dart';
import '../../lab/presentation/widgets/learning_lab_sidebar.dart';
import '../../roadmap/presentation/roadmap_explorer_widget.dart';
import '../../knowledge_graph/presentation/knowledge_graph_screen.dart';
import '../../knowledge_graph/domain/models/knowledge_graph_model.dart';
import '../../notes/presentation/notes_screen.dart';
import '../../workspace/presentation/widgets/more_workspace_hub_widget.dart';
import 'widgets/progress_timeline_widget.dart';

class PersonaRevealScreen extends ConsumerStatefulWidget {
  final VoidCallback onConfirmPersona;

  const PersonaRevealScreen({super.key, required this.onConfirmPersona});

  @override
  ConsumerState<PersonaRevealScreen> createState() => _PersonaRevealScreenState();
}

class _PersonaRevealScreenState extends ConsumerState<PersonaRevealScreen> {
  PersonaProfile? _profile;
  SubjectCluster? _cluster;
  List<CanvasGridCell> _canvasCells = [];
  List<FlashcardItem> _allFlashcards = [];
  final List<CanvasObject> _sharedCanvasObjects = [];
  final List<DrawingPath> _sharedDrawingPaths = [];
  bool _isLoading = true;

  String _activeTabId = 'roadmap'; // Default tab to roadmap
  double _chatPanelWidth = 360.0;

  final List<WorkspaceTabItem> _tabs = [
    WorkspaceTabItem(id: 'roadmap', title: 'Roadmap', icon: Icons.account_tree_outlined, isClosable: false),
    WorkspaceTabItem(id: 'mind_map', title: 'Mind Map', icon: Icons.hub_outlined, isClosable: false),
    WorkspaceTabItem(id: 'notes', title: 'Notes', icon: Icons.menu_book_rounded, isClosable: false),
    WorkspaceTabItem(id: 'flashcards', title: 'Flashcards', icon: Icons.style_outlined, isClosable: false),
    WorkspaceTabItem(id: 'lab', title: 'Learning Lab', icon: Icons.science_outlined, isClosable: false),
    WorkspaceTabItem(id: 'more', title: 'More', icon: Icons.more_horiz_rounded, isClosable: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final activeWs = ref.read(activeWorkspaceProvider);
    if (activeWs != null) {
      final wsPersona = activeWs.persona ?? PersonaProfile(
        renderMode: '3d_avatar',
        title: '${activeWs.title} Specialist',
        subtitle: 'Targeting ${activeWs.difficulty} Mastery',
        summary: 'Adaptive learning path customized for ${activeWs.subject}.',
        traits: [activeWs.difficulty, activeWs.subject],
        metrics: CognitiveMetrics(
          visualization: (0.70 + activeWs.progressPercent * 0.25).clamp(0.0, 1.0),
          applied: (0.65 + activeWs.progressPercent * 0.30).clamp(0.0, 1.0),
          theoretical: 0.70,
          pacing: 0.80,
          logic: 0.85,
        ),
        blueprintNodes: [],
      );

      if (mounted) {
        setState(() {
          _profile = wsPersona;
          _cluster = activeWs.subjectCluster;
          _allFlashcards = activeWs.flashcards;
          _canvasCells = activeWs.canvasCells;
          _sharedCanvasObjects.clear();
          _sharedCanvasObjects.addAll(activeWs.canvasObjects);
          _activeTabId = activeWs.activeTabId;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _profile = null;
        _cluster = null;
        _canvasCells = [];
        _allFlashcards = [];
        _sharedCanvasObjects.clear();
        _isLoading = false;
      });
    }
  }

  void _updateActiveContext(String newContext) {
    final activeWs = ref.read(activeWorkspaceProvider);
    if (activeWs != null) {
      ref.read(workspaceListProvider.notifier).updateActiveLearningContext(activeWs.id, newContext);
    }
  }

  void _openLearningLab(String title) {
    _updateActiveContext(title);
    setState(() {
      _activeTabId = 'lab';
    });
    final activeWs = ref.read(activeWorkspaceProvider);
    if (activeWs != null) {
      ref.read(workspaceListProvider.notifier).updateActiveTab(activeWs.id, 'lab');
    }
  }

  void _undoBackToRoadmap() {
    setState(() {
      _activeTabId = 'mind_map';
    });
    final activeWs = ref.read(activeWorkspaceProvider);
    if (activeWs != null) {
      ref.read(workspaceListProvider.notifier).updateActiveTab(activeWs.id, 'mind_map');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeWorkspaceProvider, (previous, next) {
      if (next != null && (previous == null || previous.id != next.id)) {
        setState(() {
          if (next.persona != null) _profile = next.persona;
          _cluster = next.subjectCluster;
          _allFlashcards = next.flashcards;
          _canvasCells = next.canvasCells;
          _sharedCanvasObjects.clear();
          _sharedCanvasObjects.addAll(next.canvasObjects);
          _activeTabId = next.activeTabId;
        });
      }
    });

    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Column(
        children: [
          // Chrome / Antigravity Top Workspace Tab Bar
          TopTabBarWidget(
            tabs: _tabs,
            activeTabId: _activeTabId,
            onTabSelected: (tabId) {
              setState(() {
                _activeTabId = tabId;
              });
              final activeWs = ref.read(activeWorkspaceProvider);
              if (activeWs != null) {
                ref.read(workspaceListProvider.notifier).updateActiveTab(activeWs.id, tabId);
              }
            },
            onTabClosed: (tabId) {},
          ),

          // Active Workspace Tab Content (Dynamic Resizable Split-Screen)
          Expanded(
            child: _isLoading || _profile == null || _cluster == null
                ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                : _buildTabWorkspaceContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabWorkspaceContent(BuildContext context) {
    final colors = context.colors;
    // Resizable Split Screen Layout with Draggable Splitter
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          final maxChatWidth = constraints.maxWidth - 300.0;
          return Row(
            children: [
              // Left Viewport (Flexible Canvas/Tab Area)
              Expanded(
                child: Container(
                  color: colors.bgCanvas,
                  child: _buildLeftPaneContent(context),
                ),
              ),

              // Dynamic Draggable Splitter Handle Bar
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _chatPanelWidth -= details.delta.dx;
                    _chatPanelWidth = _chatPanelWidth.clamp(260.0, maxChatWidth);
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: 6,
                    color: colors.bgActivityBar,
                    child: Center(
                      child: VerticalDivider(
                        color: colors.borderSubtle,
                        thickness: 1,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Right Pane: Dynamic Resizable AI Chatbot Panel / Roadmap Sidebar
              SizedBox(
                width: _chatPanelWidth,
                child: LearningLabSidebar(
                  onInterviewComplete: widget.onConfirmPersona,
                  onSelectNode: _openLearningLab,
                ),
              ),
            ],
          );
        } else {
          return _buildLeftPaneContent(context);
        }
      },
    );
  }

  Widget _buildLeftPaneContent(BuildContext context) {
    final activeWs = ref.watch(activeWorkspaceProvider);
    final currentContext = activeWs?.activeLearningContext ?? activeWs?.subject ?? 'Getting Started';
    final currentRoadmap = activeWs?.roadmap ?? [];
    final colors = context.colors;

    Widget content;
    switch (_activeTabId) {
      case 'roadmap':
        content = RoadmapExplorerWidget(
          roadmap: currentRoadmap,
          activeLearningContext: currentContext,
          onSelectNode: _updateActiveContext,
          onLaunchInLab: (title) => _openLearningLab(title),
        );
        break;
      case 'notes':
      case 'canvas':
        content = const NotesScreen();
        break;
      case 'flashcards':
      case 'flashcard_canvas':
        content = FlashcardCanvasWidget(
          cards: _allFlashcards,
          onAttachCardToChat: (card) {
            final prompt = 'Can you explain this flashcard: "${card.front}"? (Expected answer: "${card.back}")';
            ref.read(sidebarSelectedTabProvider.notifier).state = 0;
            ref.read(chatPrefillInputProvider.notifier).state = prompt;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Attached flashcard to chat: "${card.front}"')),
            );
          },
        );
        break;
      case 'lab':
        content = LearningLabWorkspaceScreen(
          activeNodeTitle: currentContext,
          onUndoBackToMindMap: _undoBackToRoadmap,
          sharedCanvasCells: _canvasCells,
          sharedCanvasObjects: _sharedCanvasObjects,
          sharedDrawingPaths: _sharedDrawingPaths,
          isEmbedded: true,
        );
        break;
      case 'more':
      case 'persona':
        if (activeWs != null) {
          content = MoreWorkspaceHubWidget(
            workspace: activeWs,
            profile: _profile,
            onOpenLabTopic: (topic) => _openLearningLab(topic),
          );
        } else {
          content = SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildRadarChartCard(context),
                const SizedBox(height: 20),
                _buildPersonaBadgeCard(context),
              ],
            ),
          );
        }
        break;
      case 'progress': // Legacy progress timeline view
        content = ProgressTimelineWidget(
          nodes: _profile!.blueprintNodes,
          onSelectModule: _openLearningLab,
        );
        break;
      case 'mind_map':
      default:
        final graph = activeWs?.subjectCluster != null
            ? _buildGraphFromCluster(activeWs!.subjectCluster!)
            : null;
        content = KnowledgeGraphScreen(
          initialWorkspaceId: activeWs?.id ?? '',
          graph: graph,
          onNodeSelected: (label) => _updateActiveContext(label),
          onLaunchLearningLab: (label) => _openLearningLab(label),
        );
        break;
    }

    if (activeWs != null && !activeWs.isCourseConfirmed) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: colors.bgActivityBar,
              border: Border(bottom: BorderSide(color: colors.borderSubtle)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Text(
                  'Customize your curriculum in the chat, or confirm to generate content.',
                  style: TextStyle(color: colors.fgPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.fgInverse,
                  ),
                  onPressed: () {
                    setState(() {
                      activeWs.isCourseConfirmed = true;
                    });
                    ref.read(workspaceListProvider.notifier).confirmCourse(activeWs.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Curriculum confirmed! Studio unlocked.'),
                        backgroundColor: Color(0xFF10B981),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Confirm Curriculum', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    }
    return content;
  }

  // 5-Axis Cognitive Radar Chart Component
  Widget _buildRadarChartCard(BuildContext context) {
    final m = _profile!.metrics;
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_outlined, color: colors.fgAccent, size: 20),
              const SizedBox(width: 8),
              Text('Cognitive Radar Matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: colors.accentPrimary.withValues(alpha: 0.2),
                    borderColor: colors.accentPrimary,
                    entryRadius: 3,
                    borderWidth: 2,
                    dataEntries: [
                      RadarEntry(value: m.visualization * 100),
                      RadarEntry(value: m.applied * 100),
                      RadarEntry(value: m.theoretical * 100),
                      RadarEntry(value: m.pacing * 100),
                      RadarEntry(value: m.logic * 100),
                    ],
                  ),
                ],
                radarShape: RadarShape.polygon,
                radarBorderData: BorderSide(color: colors.borderSubtle, width: 1),
                gridBorderData: BorderSide(color: colors.borderSubtle, width: 0.6),
                tickBorderData: const BorderSide(color: Colors.transparent),
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                getTitle: (index, angle) {
                  switch (index) {
                    case 0:
                      return RadarChartTitle(text: 'Visual (${(m.visualization * 100).toInt()}%)');
                    case 1:
                      return RadarChartTitle(text: 'Practical (${(m.applied * 100).toInt()}%)');
                    case 2:
                      return RadarChartTitle(text: 'Theory (${(m.theoretical * 100).toInt()}%)');
                    case 3:
                      return RadarChartTitle(text: 'Pacing (${(m.pacing * 100).toInt()}%)');
                    case 4:
                      return RadarChartTitle(text: 'Architecture (${(m.logic * 100).toInt()}%)');
                    default:
                      return const RadarChartTitle(text: '');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Persona Trait Badge Card Component
  Widget _buildPersonaBadgeCard(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.accentEmerald.withValues(alpha: 0.3)),
                ),
                child: Text('IDENTIFIED COGNITIVE PERSONA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.accentEmerald)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _profile!.title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.fgPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            _profile!.subtitle,
            style: TextStyle(fontSize: 13, color: colors.fgAccent, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          Text(
            _profile!.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.fgSecondary),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _profile!.traits.map((trait) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 14, color: colors.accentEmerald),
                    const SizedBox(width: 6),
                    Text(trait, style: TextStyle(fontSize: 12, color: colors.fgPrimary, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  KnowledgeGraph _buildGraphFromCluster(SubjectCluster cluster) {
    final List<GraphNode> nodes = [];
    final List<GraphEdge> edges = [];
    int edgeIdx = 0;

    void walk(ConceptNode cn, String? parentId) {
      final nodeType = cn.depthLevel == 0
          ? NodeType.section
          : cn.isTerminal
              ? NodeType.subtopic
              : NodeType.topic;
      final childIds = cn.children.map((c) => c.id).toList();
      nodes.add(GraphNode(
        id: cn.id,
        type: nodeType,
        label: cn.label,
        description: '',
        parentId: parentId,
        childrenNodeIds: childIds,
        // Dummy geometry — LayoutManager.computeLayout() overwrites this
        geometry: const NodeGeometry(x: 0, y: 0, width: 180, height: 50),
      ));
      if (parentId != null) {
        edges.add(GraphEdge(
          id: 'e_${edgeIdx++}',
          sourceNodeId: parentId,
          targetNodeId: cn.id,
        ));
      }
      for (final child in cn.children) {
        walk(child, cn.id);
      }
    }

    walk(cluster.rootNode, null);
    return KnowledgeGraph(
      graphId: cluster.subjectId,
      title: cluster.subjectTitle,
      description: '',
      nodes: nodes,
      edges: edges,
    );
  }
}
