class ConceptNode {
  final String id;
  final String label;
  final int depthLevel; // 0 = Subject Center, 1 = Primary Sub-topic, 2 = Deep Sub-topic
  final bool isTerminal; // If true, clicking launches Learning Lab Canvas
  bool isExpanded;
  bool isMastered;
  final List<ConceptNode> children;

  ConceptNode({
    required this.id,
    required this.label,
    this.depthLevel = 1,
    this.isTerminal = false,
    this.isExpanded = false,
    this.isMastered = false,
    List<ConceptNode>? children,
  }) : children = children ?? [];

  double get dynamicRadius {
    if (depthLevel == 0) return 46.0;
    if (depthLevel == 1) return 32.0;
    return 24.0;
  }
}

class SubjectCluster {
  final String subjectId;
  final String subjectTitle;
  final ConceptNode rootNode;

  SubjectCluster({
    required this.subjectId,
    required this.subjectTitle,
    required this.rootNode,
  });
}
