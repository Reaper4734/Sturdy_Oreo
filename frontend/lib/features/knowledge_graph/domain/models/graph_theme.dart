
/// Theme-based layout configuration and spacing constants for the Knowledge Graph pipeline.
class GraphTheme {
  final double layerSpacing;
  final double branchSpacing;
  final double groupSpacing;
  final double nodeSpacing;
  final double edgeRadius;
  final double cornerRadius;
  final double containerHorizontalPadding;
  final double containerVerticalPadding;
  final double trunkCenterX;
  final double branchOffsetX;

  const GraphTheme({
    this.layerSpacing = 72.0,
    this.branchSpacing = 20.0,
    this.groupSpacing = 32.0,
    this.nodeSpacing = 24.0,
    this.edgeRadius = 8.0,
    this.cornerRadius = 12.0,
    this.containerHorizontalPadding = 20.0,
    this.containerVerticalPadding = 16.0,
    this.trunkCenterX = 600.0,
    this.branchOffsetX = 250.0,
  });

  static const GraphTheme defaultTheme = GraphTheme();
}
