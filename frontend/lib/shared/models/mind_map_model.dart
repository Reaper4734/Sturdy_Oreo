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
  factory ConceptNode.fromJson(Map<String, dynamic> json) {
    return ConceptNode(
      id: json['id'] as String,
      label: json['label'] as String,
      depthLevel: json['depthLevel'] as int? ?? 1,
      isTerminal: json['isTerminal'] as bool? ?? false,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => ConceptNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'depthLevel': depthLevel,
      'isTerminal': isTerminal,
      'children': children.map((c) => c.toJson()).toList(),
    };
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

  factory SubjectCluster.fromJson(Map<String, dynamic> json) {
    return SubjectCluster(
      subjectId: json['subjectId'] as String,
      subjectTitle: json['subjectTitle'] as String,
      rootNode: ConceptNode.fromJson(json['rootNode'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'subjectTitle': subjectTitle,
      'rootNode': rootNode.toJson(),
    };
  }
}
