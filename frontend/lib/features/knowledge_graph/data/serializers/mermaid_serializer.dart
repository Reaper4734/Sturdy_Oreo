import '../../domain/models/knowledge_graph_model.dart';

/// Serializes a KnowledgeGraph into standard Mermaid markdown syntax (.mmd).
/// In strict adherence to Ponytail principles and architectural rules:
/// Mermaid is NEVER used as the runtime renderer. It is strictly an export format.
class MermaidSerializer {
  static String exportToMermaid(KnowledgeGraph graph) {
    final buffer = StringBuffer();
    buffer.writeln('%% Oreo Knowledge Graph Export: ${graph.title} (v${graph.version})');
    buffer.writeln('%% Exported from Oreo AI Tutor Workspace');
    buffer.writeln('graph TD');

    // 1. Define Node Styles and Styling Classes
    buffer.writeln('  classDef section fill:#1E293B,stroke:#38BDF8,stroke-width:2px,color:#ECECEC;');
    buffer.writeln('  classDef topic fill:#0D9488,stroke:#67E8F9,stroke-width:2px,color:#FFFFFF;');
    buffer.writeln('  classDef subtopic fill:#334155,stroke:#94A3B8,stroke-width:1px,color:#ECECEC;');
    buffer.writeln('  classDef quiz fill:#6B21A8,stroke:#C084FC,stroke-width:2px,color:#FFFFFF;');
    buffer.writeln('  classDef project fill:#065F46,stroke:#10B981,stroke-width:2px,color:#FFFFFF;');
    buffer.writeln('  classDef assessment fill:#9A3412,stroke:#FB923C,stroke-width:2px,color:#FFFFFF;');
    buffer.writeln('  classDef optional fill:#1E293B,stroke:#64748B,stroke-dasharray: 4 4,color:#94A3B8;');

    // 2. Map Node IDs to clean Mermaid alphanumeric IDs
    final Map<String, String> idMap = {};
    for (int i = 0; i < graph.nodes.length; i++) {
      final node = graph.nodes[i];
      final cleanId = 'N${i}_${node.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
      idMap[node.id] = cleanId;

      final escapedLabel = node.label.replaceAll('"', "'");
      final shapeStart = _getShapeStart(node.type);
      final shapeEnd = _getShapeEnd(node.type);

      buffer.writeln('  $cleanId$shapeStart"$escapedLabel"$shapeEnd');

      // Assign style class
      final styleClass = _getStyleClass(node);
      buffer.writeln('  class $cleanId $styleClass;');
    }

    buffer.writeln('');

    // 3. Define Directed Edges
    for (final edge in graph.edges) {
      final source = idMap[edge.sourceNodeId];
      final target = idMap[edge.targetNodeId];
      if (source != null && target != null) {
        final arrow = edge.style.isDashed ? '-.->' : '-->';
        buffer.writeln('  $source $arrow $target');
      }
    }

    return buffer.toString();
  }

  static String _getShapeStart(NodeType type) {
    switch (type) {
      case NodeType.section:
      case NodeType.topic:
        return '['; // Rectangle
      case NodeType.subtopic:
      case NodeType.alternative:
      case NodeType.resource:
      case NodeType.reference:
        return '('; // Rounded rectangle
      case NodeType.quiz:
      case NodeType.assessment:
        return '{{'; // Hexagon / diamond
      case NodeType.project:
        return '[['; // Subroutine box
      case NodeType.optional:
        return '>'; // Flag box
    }
  }

  static String _getShapeEnd(NodeType type) {
    switch (type) {
      case NodeType.section:
      case NodeType.topic:
        return ']';
      case NodeType.subtopic:
      case NodeType.alternative:
      case NodeType.resource:
      case NodeType.reference:
        return ')';
      case NodeType.quiz:
      case NodeType.assessment:
        return '}}';
      case NodeType.project:
        return ']]';
      case NodeType.optional:
        return ']';
    }
  }

  static String _getStyleClass(GraphNode node) {
    if (node.isOptional) return 'optional';
    switch (node.type) {
      case NodeType.section:
        return 'section';
      case NodeType.topic:
        return 'topic';
      case NodeType.subtopic:
      case NodeType.alternative:
      case NodeType.resource:
      case NodeType.reference:
        return 'subtopic';
      case NodeType.quiz:
        return 'quiz';
      case NodeType.project:
        return 'project';
      case NodeType.assessment:
        return 'assessment';
      case NodeType.optional:
        return 'optional';
    }
  }
}
