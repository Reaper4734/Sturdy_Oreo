/// Generic Learning Node for the Roadmap-Centric Learning Architecture.
/// Supports arbitrary AI-generated hierarchies (Days, Weeks, Modules, Phases, Milestones, Topics)
/// without hardcoded type assumptions.

enum NodeType {
  section,
  topic,
  project,
  assessment,
  capstone,
}

class RoadmapEdge {
  final String from;
  final String to;

  RoadmapEdge({required this.from, required this.to});

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
  };
}
class RoadmapNode {
  final String id;
  final String title;               // e.g., "Python OOP", "Inheritance", "Component State"
  final String? subtitle;           // rationale
  final NodeType type;
  final int? estimatedHours;
  final String? difficulty;
  final double progressPercent;     // 0.0 to 1.0
  final String? todaysGoal;         // e.g., "Inheritance" or "Custom Hooks"
  final String? estimatedTime;      // e.g., "5 Days", "2 Hours", "45 Mins"
  String status;                    // 'Not Started', 'In Progress', 'Completed'
  final String? activityType;       
  final int flashcardsCount;
  final int canvasNotesCount;
  final int labsCount;
  final List<String> prerequisites; // For backwards compatibility if needed
  final List<String> resources;
  final List<RoadmapNode> children; 
  bool isExpanded;
  bool isSelected;

  RoadmapNode({
    required this.id,
    required this.title,
    this.subtitle,
    this.type = NodeType.topic,
    this.estimatedHours,
    this.difficulty,
    this.progressPercent = 0.0,
    this.todaysGoal,
    this.estimatedTime,
    this.status = 'Not Started',
    this.activityType,
    this.flashcardsCount = 0,
    this.canvasNotesCount = 0,
    this.labsCount = 0,
    this.prerequisites = const [],
    this.resources = const [],
    List<RoadmapNode>? children,
    this.isExpanded = false,
    this.isSelected = false,
  }) : children = children ?? [];

  /// Returns the total count of descendant nodes in this branch.
  int get totalNodeCount {
    if (children.isEmpty) return 1;
    return children.fold(0, (sum, child) => sum + child.totalNodeCount);
  }

  /// Deep clone for state immutability in Riverpod providers.
  RoadmapNode clone() {
    return RoadmapNode(
      id: id,
      title: title,
      subtitle: subtitle,
      progressPercent: progressPercent,
      todaysGoal: todaysGoal,
      estimatedTime: estimatedTime,
      status: status,
      activityType: activityType,
      flashcardsCount: flashcardsCount,
      canvasNotesCount: canvasNotesCount,
      labsCount: labsCount,
      prerequisites: List.from(prerequisites),
      resources: List.from(resources),
      children: children.map((c) => c.clone()).toList(),
      isExpanded: isExpanded,
      isSelected: isSelected,
    );
  }

  /// Recursively searches this node and its children for a matching title or id.
  RoadmapNode? findNode(String query) {
    if (id == query || title.toLowerCase() == query.toLowerCase()) {
      return this;
    }
    for (final child in children) {
      final found = child.findNode(query);
      if (found != null) return found;
    }
    return null;
  }
}
