import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/mind_map_model.dart';

class MindMapClusterWidget extends StatefulWidget {
  final SubjectCluster cluster;
  final ValueChanged<ConceptNode> onNodeSelected;
  final ValueChanged<ConceptNode> onTerminalNodeSelected;

  const MindMapClusterWidget({
    super.key,
    required this.cluster,
    required this.onNodeSelected,
    required this.onTerminalNodeSelected,
  });

  @override
  State<MindMapClusterWidget> createState() => _MindMapClusterWidgetState();
}

class _MindMapClusterWidgetState extends State<MindMapClusterWidget> {
  final TransformationController _transformationController = TransformationController();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _transformationController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale < 3.0) {
      _transformationController.value = Matrix4.copy(_transformationController.value)..scaleByDouble(1.2, 1.2, 1.2, 1.0);
      setState(() {});
    }
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 0.4) {
      _transformationController.value = Matrix4.copy(_transformationController.value)..scaleByDouble(0.8, 0.8, 0.8, 1.0);
      setState(() {});
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {});
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
      if (isCtrlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.equal || event.logicalKey == LogicalKeyboardKey.add) {
          _zoomIn();
        } else if (event.logicalKey == LogicalKeyboardKey.minus) {
          _zoomOut();
        } else if (event.logicalKey == LogicalKeyboardKey.digit0) {
          _resetZoom();
        }
      }
    }
  }

  void _toggleNode(ConceptNode node) {
    if (node.isTerminal) {
      widget.onTerminalNodeSelected(node);
    } else {
      setState(() {
        node.isExpanded = !node.isExpanded; // Re-click toggles collapse
      });
      widget.onNodeSelected(node);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: colors.bgCanvas,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.4,
          maxScale: 3.0,
          boundaryMargin: const EdgeInsets.all(600),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(100.0),
                  child: CustomPaint(
                    painter: MindMapOutwardLinesPainter(rootNode: widget.cluster.rootNode, lineColor: colors.borderSubtle),
                    child: _buildNodeTreeWidget(context, widget.cluster.rootNode, const Offset(450, 400)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Recursive Node Tree Render Widget
  Widget _buildNodeTreeWidget(BuildContext context, ConceptNode node, Offset centerOffset) {
    return SizedBox(
      width: 900,
      height: 800,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Central Root Node
          Positioned(
            left: centerOffset.dx - node.dynamicRadius,
            top: centerOffset.dy - node.dynamicRadius,
            child: _buildNodeBubble(context, node),
          ),

          // Render Child Nodes Radially (Depth 1)
          if (node.isExpanded && node.children.isNotEmpty) ..._buildChildNodesRadially(context, node, centerOffset),
        ],
      ),
    );
  }

  // Depth 1 Primary Children (Distributed 360 Degrees around Root)
  List<Widget> _buildChildNodesRadially(BuildContext context, ConceptNode parent, Offset parentCenter) {
    final List<Widget> widgets = [];
    final int childCount = parent.children.length;
    const double radius = 210.0; // Increased radius to avoid overlap

    for (int i = 0; i < childCount; i++) {
      final child = parent.children[i];
      final double angle = (2 * pi * i / childCount) - (pi / 2);
      final double childX = parentCenter.dx + radius * cos(angle);
      final double childY = parentCenter.dy + radius * sin(angle);

      widgets.add(
        Positioned(
          left: childX - child.dynamicRadius,
          top: childY - child.dynamicRadius,
          child: _buildNodeBubble(context, child),
        ),
      );

      // Depth 2 Sub-children (Radiating OUTWARDS in a fan arc centered on angle)
      if (child.isExpanded && child.children.isNotEmpty) {
        widgets.addAll(_buildGrandChildrenOutward(context, child, Offset(childX, childY), angle));
      }
    }
    return widgets;
  }

  // Depth 2 Sub-children (Radiates OUTWARDS away from Central Root to prevent overlap)
  List<Widget> _buildGrandChildrenOutward(BuildContext context, ConceptNode parent, Offset parentCenter, double baseAngle) {
    final List<Widget> widgets = [];
    final int childCount = parent.children.length;
    const double subRadius = 110.0;
    const double arcSpread = pi / 1.8; // 100 degree fan arc outwards

    final double startAngle = baseAngle - (arcSpread / 2);
    final double stepAngle = childCount > 1 ? arcSpread / (childCount - 1) : 0;

    for (int i = 0; i < childCount; i++) {
      final child = parent.children[i];
      final double subAngle = childCount > 1 ? (startAngle + i * stepAngle) : baseAngle;
      final double childX = parentCenter.dx + subRadius * cos(subAngle);
      final double childY = parentCenter.dy + subRadius * sin(subAngle);

      widgets.add(
        Positioned(
          left: childX - child.dynamicRadius,
          top: childY - child.dynamicRadius,
          child: _buildNodeBubble(context, child),
        ),
      );
    }
    return widgets;
  }

  // Overflow-Free Node Bubble Component
  Widget _buildNodeBubble(BuildContext context, ConceptNode node) {
    final colors = context.colors;
    final double r = node.dynamicRadius;
    final bool isRoot = node.depthLevel == 0;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return InkWell(
      onTap: () => _toggleNode(node),
      borderRadius: BorderRadius.circular(r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: r * 2,
        height: r * 2,
        padding: EdgeInsets.all(isRoot ? 10 : (node.depthLevel == 1 ? 6 : 4)),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRoot
              ? colors.accentPrimary
              : (node.isTerminal
                  ? colors.accentEmerald.withValues(alpha: 0.15)
                  : (node.isExpanded ? colors.bgElevated : colors.bgSurface)),
          border: Border.all(
            color: isRoot
                ? colors.accentPrimary
                : (node.isTerminal ? colors.accentEmerald : (node.isExpanded ? colors.borderActive : colors.borderSubtle)),
            width: isRoot ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isRoot
                  ? colors.accentPrimary.withValues(alpha: 0.25)
                  : (isLight ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.3)),
              blurRadius: isRoot ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Prevents RenderFlex overflow
            children: [
              if (node.isTerminal)
                Icon(Icons.play_circle_fill_rounded, size: 12, color: colors.accentEmerald),
              Flexible(
                child: Text(
                  node.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isRoot ? 12 : (node.depthLevel == 1 ? 10 : 8.5),
                    fontWeight: isRoot ? FontWeight.bold : FontWeight.w600,
                    color: isRoot ? colors.fgInverse : colors.fgPrimary,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Outward Lines Painter for Radial Node Tree
class MindMapOutwardLinesPainter extends CustomPainter {
  final ConceptNode rootNode;
  final Color lineColor;

  MindMapOutwardLinesPainter({required this.rootNode, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const Offset center = Offset(450, 400);

    if (rootNode.isExpanded && rootNode.children.isNotEmpty) {
      _paintChildrenLines(canvas, paint, rootNode, center);
    }
  }

  void _paintChildrenLines(Canvas canvas, Paint paint, ConceptNode parent, Offset parentCenter) {
    final int childCount = parent.children.length;
    const double radius = 210.0;

    for (int i = 0; i < childCount; i++) {
      final child = parent.children[i];
      final double angle = (2 * pi * i / childCount) - (pi / 2);
      final double childX = parentCenter.dx + radius * cos(angle);
      final double childY = parentCenter.dy + radius * sin(angle);

      canvas.drawLine(parentCenter, Offset(childX, childY), paint);

      if (child.isExpanded && child.children.isNotEmpty) {
        _paintGrandChildrenOutward(canvas, paint, child, Offset(childX, childY), angle);
      }
    }
  }

  void _paintGrandChildrenOutward(Canvas canvas, Paint paint, ConceptNode parent, Offset parentCenter, double baseAngle) {
    final int childCount = parent.children.length;
    const double subRadius = 110.0;
    const double arcSpread = pi / 1.8;

    final double startAngle = baseAngle - (arcSpread / 2);
    final double stepAngle = childCount > 1 ? arcSpread / (childCount - 1) : 0;

    for (int i = 0; i < childCount; i++) {
      final double subAngle = childCount > 1 ? (startAngle + i * stepAngle) : baseAngle;
      final double childX = parentCenter.dx + subRadius * cos(subAngle);
      final double childY = parentCenter.dy + subRadius * sin(subAngle);

      canvas.drawLine(parentCenter, Offset(childX, childY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
