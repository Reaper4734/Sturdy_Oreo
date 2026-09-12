import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/models/knowledge_graph_model.dart';
import '../domain/models/graph_state.dart';
import '../domain/models/layout_result.dart';
import '../domain/layout/layout_manager.dart';
import '../domain/layout/viewport_manager.dart';
import '../data/serializers/mermaid_serializer.dart';
import 'renderers/graph_edges_painter.dart';
import 'renderers/graph_group_painter.dart';
import 'widgets/graph_node_widget.dart';

/// Primary screen component for the Oreo Knowledge Graph Engine.
/// Operates as a 100% dumb renderer: performs zero layout calculations or overlap resolution.
/// Strictly paints LayoutResult coordinates and applies viewport virtualization for high scalability.
class KnowledgeGraphScreen extends StatefulWidget {
  final String initialWorkspaceId;
  final KnowledgeGraph? graph;
  final Function(String) onNodeSelected;
  final Function(String) onLaunchLearningLab;

  const KnowledgeGraphScreen({
    super.key,
    this.initialWorkspaceId = '',
    this.graph,
    required this.onNodeSelected,
    required this.onLaunchLearningLab,
  });

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> {
  late String _currentWorkspaceId;
  late KnowledgeGraph _graph;
  late GraphState _graphState;
  final LayoutManager _layoutManager = LayoutManager();

  LayoutResult? _layoutResult;

  final TransformationController _transformController = TransformationController();
  Size? _viewportSize;

  @override
  void initState() {
    super.initState();
    _currentWorkspaceId = widget.initialWorkspaceId;
    _loadGraph(_currentWorkspaceId);
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant KnowledgeGraphScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph || oldWidget.initialWorkspaceId != widget.initialWorkspaceId) {
      _loadGraph(widget.initialWorkspaceId);
    }
  }

  void _loadGraph(String workspaceId) {
    setState(() {
      _currentWorkspaceId = workspaceId;
      _graph = widget.graph ?? KnowledgeGraph(graphId: workspaceId, title: 'Empty', description: '', nodes: [], edges: []);
      final initialSelectedId = _graph.nodes.isNotEmpty ? _graph.nodes.first.id : null;
      _graphState = GraphState(
        activeWorkspaceId: workspaceId,
        selectedNodeId: initialSelectedId,
      );
      _layoutResult = _layoutManager.computeLayout(_graph);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToScreen();
    });
  }

  void _onSelectNode(GraphNode node) {
    final searchRes = _layoutManager.handleSearch(node.id, _graph, _graphState);
    setState(() {
      _graphState = searchRes.state.copyWith(selectedNodeId: node.id);
      _layoutResult = searchRes.layoutResult;
    });
    widget.onNodeSelected(node.label);
    _centerOnNodeId(node.id);
  }

  void _centerOnNodeId(String nodeId) {
    final geom = _layoutResult?.nodeGeometries[nodeId];
    if (geom == null) return;

    final Size viewportSize = _viewportSize ?? MediaQuery.of(context).size;
    final double zoom = _transformController.value.getMaxScaleOnAxis();
    final Offset targetOffset = ViewportManager.calculateFocusOffset(geom, viewportSize, zoom);

    _transformController.value = Matrix4.identity()
      ..translateByDouble(targetOffset.dx, targetOffset.dy, 0.0, 1.0)
      ..scaleByDouble(zoom, zoom, 1.0, 1.0);
  }

  void _fitToScreen() {
    if (_layoutResult == null) return;
    final Size viewportSize = _viewportSize ?? MediaQuery.of(context).size;
    if (viewportSize.isEmpty) return;

    final fit = ViewportManager.calculateFitToScreen(_layoutResult!.totalBounds, viewportSize);
    _transformController.value = Matrix4.identity()
      ..translateByDouble(fit.offset.dx, fit.offset.dy, 0.0, 1.0)
      ..scaleByDouble(fit.zoom, fit.zoom, 1.0, 1.0);
  }

  void _zoomIn() {
    final double zoom = _transformController.value.getMaxScaleOnAxis();
    if (zoom >= _graph.viewportDefaults.maxZoom) return;
    _scaleViewport(1.2);
  }

  void _zoomOut() {
    final double zoom = _transformController.value.getMaxScaleOnAxis();
    if (zoom <= _graph.viewportDefaults.minZoom) return;
    _scaleViewport(1 / 1.2);
  }

  void _scaleViewport(double factor) {
    final Size size = _viewportSize ?? MediaQuery.of(context).size;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Matrix4 matrix = _transformController.value;

    final Matrix4 scaled = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0.0, 1.0)
      ..scaleByDouble(factor, factor, 1.0, 1.0)
      ..translateByDouble(-center.dx, -center.dy, 0.0, 1.0)
      ..multiply(matrix);

    _transformController.value = scaled;
  }

  void _exportToMermaid() {
    final colors = context.colors;
    final mmd = MermaidSerializer.exportToMermaid(_graph);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.borderSubtle),
        ),
        title: Text('Export Graph to Mermaid', style: TextStyle(color: colors.fgPrimary, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy this markdown snippet into Obsidian, GitHub, or any Mermaid renderer:',
                style: TextStyle(color: colors.fgSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                height: 240,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    mmd,
                    style: TextStyle(color: colors.accentCyan, fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: colors.fgSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: colors.accentCyan),
            icon: const Icon(Icons.copy, color: Colors.white, size: 16),
            label: const Text('Copy to Clipboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: mmd));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export Knowledge Graph', style: TextStyle(color: colors.fgPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.code, color: colors.accentCyan),
                title: Text('Mermaid Markdown (.mmd)', style: TextStyle(color: colors.fgPrimary)),
                subtitle: Text('Text-based export for docs and wikis', style: TextStyle(color: colors.fgSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  _exportToMermaid();
                },
              ),
              ListTile(
                leading: Icon(Icons.image, color: colors.accentEmerald),
                title: Text('Scalable Vector Graphics (.svg)', style: TextStyle(color: colors.fgPrimary)),
                subtitle: Text('Standalone vector diagram', style: TextStyle(color: colors.fgSecondary)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_size_select_actual, color: Color(0xFFF59E0B)),
                title: Text('High-Resolution PNG (.png)', style: TextStyle(color: colors.fgPrimary)),
                subtitle: Text('Raster image for slides and reports', style: TextStyle(color: colors.fgSecondary)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
                title: Text('PDF Document (.pdf)', style: TextStyle(color: colors.fgPrimary)),
                subtitle: Text('Printable multi-page document', style: TextStyle(color: colors.fgSecondary)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_layoutResult == null) {
      return Scaffold(
        backgroundColor: colors.bgCanvas,
        body: Center(child: CircularProgressIndicator(color: colors.accentCyan)),
      );
    }

    final layout = _layoutResult!;
    final double totalW = layout.totalBounds.width;
    final double totalH = layout.totalBounds.height;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              // 1. INTERACTIVE CAMERA VIEWPORT STAGE
              InteractiveViewer(
                transformationController: _transformController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: _graph.viewportDefaults.minZoom,
                maxScale: _graph.viewportDefaults.maxZoom,
                child: Center(
                  child: SizedBox(
                    width: totalW,
                    height: totalH,
                    child: Stack(
                      children: [
                        // Layer 5a: Auto-sized container boxes
                        CustomPaint(
                          size: Size(totalW, totalH),
                          painter: GraphGroupPainter(
                            containerBoxes: layout.containerBoxes,
                            fillColor: colors.bgElevated.withValues(alpha: 0.6),
                            borderColor: colors.borderSubtle,
                          ),
                        ),
                        // Layer 5b: Routed connecting edges
                        CustomPaint(
                          size: Size(totalW, totalH),
                          painter: GraphEdgesPainter(
                            edges: layout.routedEdges,
                            activeNodeIds: _graphState.selectedNodeId != null ? {_graphState.selectedNodeId!} : {},
                            activeColor: colors.accentCyan,
                            inactiveColor: colors.borderActive,
                          ),
                        ),
                        // Layer 5c: Permanently visible nodes
                        for (final node in _graph.nodes)
                          if (layout.nodeGeometries.containsKey(node.id))
                            Positioned(
                              left: layout.nodeGeometries[node.id]!.x,
                              top: layout.nodeGeometries[node.id]!.y,
                              child: GraphNodeWidget(
                                node: node.copyWith(geometry: layout.nodeGeometries[node.id]!),
                                isSelected: node.id == _graphState.selectedNodeId,
                                onTap: () => _onSelectNode(node),
                                onLaunchActivity: () => widget.onLaunchLearningLab(node.label),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. BOTTOM RIGHT ACTION BUTTONS
              Positioned(
                bottom: 24,
                right: 24,
                child: Row(
                  children: [
                    // Zoom Controls (+, -, Fit)
                    Container(
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.zoom_in, color: colors.fgPrimary, size: 18),
                            tooltip: 'Zoom In',
                            onPressed: _zoomIn,
                          ),
                          IconButton(
                            icon: Icon(Icons.zoom_out, color: colors.fgPrimary, size: 18),
                            tooltip: 'Zoom Out',
                            onPressed: _zoomOut,
                          ),
                          IconButton(
                            icon: Icon(Icons.fit_screen, color: colors.accentCyan, size: 18),
                            tooltip: 'Fit to Screen',
                            onPressed: _fitToScreen,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Export Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.bgSurface,
                        foregroundColor: colors.fgPrimary,
                        side: BorderSide(color: colors.borderSubtle),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                      ),
                      icon: Icon(Icons.download, size: 16, color: colors.accentCyan),
                      label: const Text('Export'),
                      onPressed: _showExportOptions,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
