class CognitiveMetrics {
  final double visualization;       // Visual Intuition
  final double applied;             // Practical Execution
  final double theoretical;         // Theory Rigor
  final double pacing;              // Pacing Speed
  final double logic;               // System Architecture

  CognitiveMetrics({
    required this.visualization,
    required this.applied,
    required this.theoretical,
    required this.pacing,
    required this.logic,
  });

  // Convert to JSON / Map matching backend /api/persona/{userId}
  Map<String, dynamic> toJson() => {
        'visualization': visualization,
        'applied': applied,
        'theoretical': theoretical,
        'pacing': pacing,
        'logic': logic,
      };

  factory CognitiveMetrics.fromJson(Map<String, dynamic> json) => CognitiveMetrics(
        visualization: (json['visualization'] as num?)?.toDouble() ?? 0.8,
        applied: (json['applied'] as num?)?.toDouble() ?? 0.8,
        theoretical: (json['theoretical'] as num?)?.toDouble() ?? 0.6,
        pacing: (json['pacing'] as num?)?.toDouble() ?? 0.8,
        logic: (json['logic'] as num?)?.toDouble() ?? 0.9,
      );
}

class BlueprintNode {
  final String id;
  final String dayRange;
  final String title;
  final String description;
  final List<String> topics;
  final List<String> alternatives;
  String selectedFormat;
  bool isHandsOnFocus;

  BlueprintNode({
    required this.id,
    required this.dayRange,
    required this.title,
    required this.description,
    required this.topics,
    required this.alternatives,
    this.selectedFormat = 'Interactive Sandbox',
    this.isHandsOnFocus = true,
  });
}

class PersonaProfile {
  final String renderMode;
  final String title;
  final String subtitle;
  final String summary;
  final List<String> traits;
  final CognitiveMetrics metrics;
  final List<BlueprintNode> blueprintNodes;

  PersonaProfile({
    required this.renderMode,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.traits,
    required this.metrics,
    required this.blueprintNodes,
  });
}
