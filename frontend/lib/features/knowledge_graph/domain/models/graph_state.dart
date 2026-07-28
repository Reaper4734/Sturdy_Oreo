import 'dart:ui';

/// Manages dynamic runtime UI state without mutating the immutable KnowledgeGraph.
class GraphState {
  final String? selectedNodeId;
  final String? highlightedNodeId;
  final String activeWorkspaceId;
  final Offset viewportPosition;
  final double zoomLevel;

  const GraphState({
    this.selectedNodeId,
    this.highlightedNodeId,
    this.activeWorkspaceId = 'python_backend',
    this.viewportPosition = Offset.zero,
    this.zoomLevel = 0.85,
  });

  GraphState copyWith({
    String? selectedNodeId,
    bool clearSelectedNode = false,
    String? highlightedNodeId,
    bool clearHighlightedNode = false,
    String? activeWorkspaceId,
    Offset? viewportPosition,
    double? zoomLevel,
  }) {
    return GraphState(
      selectedNodeId: clearSelectedNode ? null : (selectedNodeId ?? this.selectedNodeId),
      highlightedNodeId: clearHighlightedNode ? null : (highlightedNodeId ?? this.highlightedNodeId),
      activeWorkspaceId: activeWorkspaceId ?? this.activeWorkspaceId,
      viewportPosition: viewportPosition ?? this.viewportPosition,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}
