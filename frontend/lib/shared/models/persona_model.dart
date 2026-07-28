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

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayRange': dayRange,
    'title': title,
    'description': description,
    'topics': topics,
    'alternatives': alternatives,
    'selectedFormat': selectedFormat,
    'isHandsOnFocus': isHandsOnFocus,
  };

  factory BlueprintNode.fromJson(Map<String, dynamic> json) => BlueprintNode(
    id: json['id'] as String,
    dayRange: json['dayRange'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    topics: (json['topics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    alternatives: (json['alternatives'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    selectedFormat: json['selectedFormat'] as String? ?? 'Interactive Sandbox',
    isHandsOnFocus: json['isHandsOnFocus'] as bool? ?? true,
  );
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

  Map<String, dynamic> toJson() => {
    'renderMode': renderMode,
    'title': title,
    'subtitle': subtitle,
    'summary': summary,
    'traits': traits,
    'metrics': metrics.toJson(),
    'blueprintNodes': blueprintNodes.map((e) => e.toJson()).toList(),
  };

  factory PersonaProfile.fromJson(Map<String, dynamic> json) => PersonaProfile(
    renderMode: json['renderMode'] as String? ?? 'default',
    title: json['title'] as String? ?? 'Learner',
    subtitle: json['subtitle'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    traits: (json['traits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    metrics: json['metrics'] != null ? CognitiveMetrics.fromJson(json['metrics']) : CognitiveMetrics(visualization: 0.8, applied: 0.8, theoretical: 0.6, pacing: 0.8, logic: 0.9),
    blueprintNodes: (json['blueprintNodes'] as List<dynamic>?)?.map((e) => BlueprintNode.fromJson(e)).toList() ?? [],
  );
}
