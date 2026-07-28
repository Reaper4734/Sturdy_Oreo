import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/models/knowledge_graph_model.dart';
import '../domain/models/graph_state.dart';
import '../domain/models/layout_result.dart';
import '../domain/layout/layout_manager.dart';
import '../domain/layout/viewport_manager.dart';
import '../data/datasources/mock_knowledge_graph_data.dart';
import '../data/serializers/mermaid_serializer.dart';
import 'renderers/graph_edges_painter.dart';
import 'renderers/graph_group_painter.dart';
import 'widgets/graph_node_widget.dart';

/// Primary screen component for the Oreo Knowledge Graph Engine.
/// Operates as a 100% dumb renderer: performs zero layout calculations or overlap resolution.
/// Strictly paints LayoutResult coordinates and applies viewport virtualization for high scalability.
class KnowledgeGraphScreen extends StatefulWidget {
  final String initialWorkspaceId;
  final Function(String) onNodeSelected;
  final Function(String) onLaunchLearningLab;

  const KnowledgeGraphScreen({
    super.key,
    this.initialWorkspaceId = 'python_backend',
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

  void _loadGraph(String workspaceId) {
    setState(() {
      _currentWorkspaceId = workspaceId;
      _graph = MockKnowledgeGraphData.getWorkspaceGraph(workspaceId);
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
    final mmd = MermaidSerializer.exportToMermaid(_graph);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Export Graph to Mermaid', style: TextStyle(color: Color(0xFFECECEC))),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy this markdown snippet into Obsidian, GitHub, or any Mermaid renderer:',
                style: TextStyle(color: Color(0xFF878787), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                height: 240,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    mmd,
                    style: const TextStyle(color: Color(0xFF67E8F9), fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF878787))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF67E8F9)),
            icon: const Icon(Icons.copy, color: Colors.black, size: 16),
            label: const Text('Copy to Clipboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export Knowledge Graph', style: TextStyle(color: Color(0xFFECECEC), fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.code, color: Color(0xFF67E8F9)),
                title: const Text('Mermaid Markdown (.mmd)', style: TextStyle(color: Color(0xFFECECEC))),
                subtitle: const Text('Text-based export for docs and wikis', style: TextStyle(color: Color(0xFF878787))),
                onTap: () {
                  Navigator.pop(context);
                  _exportToMermaid();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF10B981)),
                title: const Text('Scalable Vector Graphics (.svg)', style: TextStyle(color: Color(0xFFECECEC))),
                subtitle: const Text('Standalone vector diagram', style: TextStyle(color: Color(0xFF878787))),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_size_select_actual, color: Color(0xFFF59E0B)),
                title: const Text('High-Resolution PNG (.png)', style: TextStyle(color: Color(0xFFECECEC))),
                subtitle: const Text('Raster image for slides and reports', style: TextStyle(color: Color(0xFF878787))),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
                title: const Text('PDF Document (.pdf)', style: TextStyle(color: Color(0xFFECECEC))),
                subtitle: const Text('Printable multi-page document', style: TextStyle(color: Color(0xFF878787))),
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
    if (_layoutResult == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF67E8F9))),
      );
    }

    final layout = _layoutResult!;
    final double totalW = layout.totalBounds.width;
    final double totalH = layout.totalBounds.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              // 1. INTERACTIVE CAMERA VIEWPORT STAGE
              InteractiveViewer(
                transformationController: _transformController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(800.0),
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
                          painter: GraphGroupPainter(containerBoxes: layout.containerBoxes),
                        ),
                        // Layer 5b: Routed connecting edges
                        CustomPaint(
                          size: Size(totalW, totalH),
                          painter: GraphEdgesPainter(
                            edges: layout.routedEdges,
                            activeNodeIds: _graphState.selectedNodeId != null ? {_graphState.selectedNodeId!} : {},
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
                        color: const Color(0xFF212121),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.zoom_in, color: Color(0xFFECECEC), size: 18),
                            tooltip: 'Zoom In',
                            onPressed: _zoomIn,
                          ),
                          IconButton(
                            icon: const Icon(Icons.zoom_out, color: Color(0xFFECECEC), size: 18),
                            tooltip: 'Zoom Out',
                            onPressed: _zoomOut,
                          ),
                          IconButton(
                            icon: const Icon(Icons.fit_screen, color: Color(0xFF67E8F9), size: 18),
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
                        backgroundColor: const Color(0xFF212121),
                        foregroundColor: const Color(0xFFECECEC),
                        side: const BorderSide(color: Color(0xFF333333)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.download, size: 16, color: Color(0xFF67E8F9)),
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
