import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/learning_lab_model.dart';

enum CanvasDrawMode { select, pen, eraser }

class BoundedGridCanvasWidget extends StatefulWidget {
  final List<CanvasGridCell> gridCells;
  final List<CanvasObject> customObjects;
  final List<DrawingPath> drawingPaths;
  final ValueChanged<CanvasGridCell> onAttachDiagramToChat;
  final VoidCallback? onToggleToTranscript;

  const BoundedGridCanvasWidget({
    super.key,
    required this.gridCells,
    required this.customObjects,
    required this.drawingPaths,
    required this.onAttachDiagramToChat,
    this.onToggleToTranscript,
  });

  @override
  State<BoundedGridCanvasWidget> createState() => _BoundedGridCanvasWidgetState();
}

class _BoundedGridCanvasWidgetState extends State<BoundedGridCanvasWidget> {
  final TransformationController _transformationController = TransformationController();
  final FocusNode _keyboardFocusNode = FocusNode();

  bool _isShiftPressed = false;
  CanvasDrawMode _drawMode = CanvasDrawMode.select;
  Color? _selectedPenColor;
  double _penStrokeWidth = 2.5;
  double _penOpacity = 1.0;
  double _eraserRadius = 16.0;
  List<Offset> _currentStrokePoints = [];

  // Undo / Redo stacks
  final List<DrawingPath> _undoStack = [];

  @override
  void dispose() {
    _transformationController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  // --- Undo / Redo / Clear ---

  void _undo() {
    if (widget.drawingPaths.isNotEmpty) {
      setState(() {
        _undoStack.add(widget.drawingPaths.removeLast());
      });
    }
  }

  void _redo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        widget.drawingPaths.add(_undoStack.removeLast());
      });
    }
  }

  void _clearAll() {
    if (widget.drawingPaths.isNotEmpty) {
      setState(() {
        // Push all paths to undo stack in reverse so redo restores in order
        _undoStack.addAll(widget.drawingPaths.reversed);
        widget.drawingPaths.clear();
      });
    }
  }

  // --- Keyboard ---

  void _selectAllObjects() {
    setState(() {
      for (final cell in widget.gridCells) {
        cell.isSelected = true;
      }
      for (final obj in widget.customObjects) {
        obj.isSelected = true;
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
      _isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

      if (isCtrlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.keyA) {
          _selectAllObjects();
        } else if (event.logicalKey == LogicalKeyboardKey.keyZ) {
          if (_isShiftPressed) {
            _redo();
          } else {
            _undo();
          }
        }
      }
    } else if (event is KeyUpEvent) {
      _isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    }
  }

  // --- Canvas Bounds ---

  Size _calculateCanvasBounds() {
    double maxRight = 3200.0;
    double maxBottom = 2400.0;

    for (final cell in widget.gridCells) {
      final rect = cell.rect;
      if (rect.right + 600 > maxRight) maxRight = rect.right + 600;
      if (rect.bottom + 600 > maxBottom) maxBottom = rect.bottom + 600;
    }

    for (final obj in widget.customObjects) {
      final rect = obj.rect;
      if (rect.right + 600 > maxRight) maxRight = rect.right + 600;
      if (rect.bottom + 600 > maxBottom) maxBottom = rect.bottom + 600;
    }

    for (final path in widget.drawingPaths) {
      for (final pt in path.points) {
        if (pt.dx + 600 > maxRight) maxRight = pt.dx + 600;
        if (pt.dy + 600 > maxBottom) maxBottom = pt.dy + 600;
      }
    }

    return Size(maxRight, maxBottom);
  }

  // --- Drawing Handlers ---

  void _onPointerDown(PointerDownEvent event, Color activePenColor) {
    final scenePoint = _transformationController.toScene(event.localPosition);
    if (_drawMode == CanvasDrawMode.pen) {
      _currentStrokePoints = [scenePoint];
      _undoStack.clear();
      setState(() {});
    } else if (_drawMode == CanvasDrawMode.eraser) {
      _eraseAtPoint(scenePoint);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final scenePoint = _transformationController.toScene(event.localPosition);
    if (_drawMode == CanvasDrawMode.pen) {
      _currentStrokePoints.add(scenePoint);
      setState(() {});
    } else if (_drawMode == CanvasDrawMode.eraser) {
      _eraseAtPoint(scenePoint);
    }
  }

  void _onPointerUp(PointerUpEvent event, Color activePenColor) {
    if (_drawMode == CanvasDrawMode.pen && _currentStrokePoints.isNotEmpty) {
      final effectiveColor = activePenColor.withValues(alpha: _penOpacity);
      widget.drawingPaths.add(DrawingPath(
        points: List.from(_currentStrokePoints),
        color: effectiveColor,
        strokeWidth: _penStrokeWidth,
      ));
    }
    _currentStrokePoints = [];
    setState(() {});
  }

  void _eraseAtPoint(Offset scenePoint) {
    setState(() {
      final toRemove = <DrawingPath>[];
      for (final path in widget.drawingPaths) {
        for (final pt in path.points) {
          final dist = (pt - scenePoint).distance;
          if (dist <= _eraserRadius) {
            toRemove.add(path);
            break;
          }
        }
      }
      for (final path in toRemove) {
        widget.drawingPaths.remove(path);
        _undoStack.add(path);
      }
    });
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activePenColor = _selectedPenColor ?? colors.accentPrimary;
    final canvasSize = _calculateCanvasBounds();
    final isDrawing = _drawMode == CanvasDrawMode.pen || _drawMode == CanvasDrawMode.eraser;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgCanvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            // Canvas Header Toolbar
            _buildToolbar(context, activePenColor),

            // Canvas Area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: Listener(
                  onPointerDown: isDrawing ? (e) => _onPointerDown(e, activePenColor) : null,
                  onPointerMove: isDrawing ? _onPointerMove : null,
                  onPointerUp: isDrawing ? (e) => _onPointerUp(e, activePenColor) : null,
                  child: MouseRegion(
                    cursor: _drawMode == CanvasDrawMode.pen
                        ? SystemMouseCursors.precise
                        : _drawMode == CanvasDrawMode.eraser
                            ? SystemMouseCursors.precise
                            : SystemMouseCursors.grab,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      alignment: Alignment.topLeft,
                      constrained: false,
                      minScale: 0.4,
                      maxScale: 3.0,
                      panEnabled: !isDrawing,
                      scaleEnabled: !isDrawing,
                      boundaryMargin: const EdgeInsets.all(400),
                      child: CustomPaint(
                        size: canvasSize,
                        painter: CanvasGridBackgroundPainter(colors: colors),
                        foregroundPainter: DrawingOverlayPainter(
                          paths: widget.drawingPaths,
                          currentStroke: _currentStrokePoints,
                          currentColor: activePenColor.withValues(alpha: _penOpacity),
                          currentWidth: _penStrokeWidth,
                        ),
                        child: SizedBox(
                          width: canvasSize.width,
                          height: canvasSize.height,
                          child: Stack(
                            children: [
                              ...widget.gridCells.map((cell) => _buildGridCellCard(context, cell)),
                              ...widget.customObjects.map((obj) => _buildMovableObjectCard(context, obj)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Toolbar ---

  Widget _buildToolbar(BuildContext context, Color activePenColor) {
    final colors = context.colors;

    final colorPalette = [
      colors.accentPrimary,
      colors.accentEmerald,
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      colors.fgPrimary,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bgActivityBar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          Icon(Icons.grid_4x4_rounded, size: 14, color: colors.accentEmerald),
          const SizedBox(width: 6),
          Text('Canvas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
          const SizedBox(width: 10),

          // Divider
          _toolDivider(context),

          // Mode Tools
          _buildModeButton(context, Icons.near_me_outlined, 'Select', CanvasDrawMode.select),
          const SizedBox(width: 3),
          _buildModeButton(context, Icons.edit_rounded, 'Pen', CanvasDrawMode.pen),
          const SizedBox(width: 3),
          _buildModeButton(context, Icons.auto_fix_high_rounded, 'Eraser', CanvasDrawMode.eraser),

          const SizedBox(width: 6),
          _toolDivider(context),

          // Pen options (color palette + stroke width + opacity) — only when pen active
          if (_drawMode == CanvasDrawMode.pen) ...[
            const SizedBox(width: 4),
            ...colorPalette.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: InkWell(
                    onTap: () => setState(() => _selectedPenColor = c),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == activePenColor ? colors.fgPrimary : colors.borderSubtle,
                          width: c == activePenColor ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                )),
            const SizedBox(width: 2),

            // Stroke Width
            Tooltip(
              message: 'Stroke Width: ${_penStrokeWidth.toStringAsFixed(1)}',
              child: SizedBox(
                width: 50,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.borderSubtle,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    min: 1,
                    max: 10,
                    value: _penStrokeWidth,
                    onChanged: (v) => setState(() => _penStrokeWidth = v),
                  ),
                ),
              ),
            ),
            _toolDivider(context),

            // Opacity
            Tooltip(
              message: 'Opacity: ${(_penOpacity * 100).toInt()}%',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.opacity_rounded, size: 12, color: colors.fgSecondary),
                  SizedBox(
                    width: 46,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        activeTrackColor: colors.accentEmerald,
                        inactiveTrackColor: colors.borderSubtle,
                        thumbColor: colors.accentEmerald,
                      ),
                      child: Slider(
                        min: 0.15,
                        max: 1.0,
                        value: _penOpacity,
                        onChanged: (v) => setState(() => _penOpacity = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Eraser size — only when eraser active
          if (_drawMode == CanvasDrawMode.eraser) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'Eraser Size: ${_eraserRadius.toInt()}px',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Size', style: TextStyle(fontSize: 10, color: colors.fgSecondary)),
                  SizedBox(
                    width: 60,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        activeTrackColor: colors.accentPrimary,
                        inactiveTrackColor: colors.borderSubtle,
                        thumbColor: colors.accentPrimary,
                      ),
                      child: Slider(
                        min: 8,
                        max: 40,
                        value: _eraserRadius,
                        onChanged: (v) => setState(() => _eraserRadius = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Undo
          _buildActionIcon(
            context,
            Icons.undo_rounded,
            'Undo (Ctrl+Z)',
            widget.drawingPaths.isNotEmpty ? _undo : null,
          ),
          // Redo
          _buildActionIcon(
            context,
            Icons.redo_rounded,
            'Redo (Ctrl+Shift+Z)',
            _undoStack.isNotEmpty ? _redo : null,
          ),
          const SizedBox(width: 2),
          // Clear
          _buildActionIcon(
            context,
            Icons.delete_outline_rounded,
            'Clear All',
            widget.drawingPaths.isNotEmpty ? _clearAll : null,
          ),

          // Toggle to Transcript (when inline below video)
          if (widget.onToggleToTranscript != null) ...[
            const SizedBox(width: 6),
            _toolDivider(context),
            const SizedBox(width: 6),
            InkWell(
              onTap: widget.onToggleToTranscript,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgCanvas,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.style_outlined, size: 12, color: colors.accentEmerald),
                    const SizedBox(width: 4),
                    Text('Show Flashcards', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.accentEmerald)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolDivider(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colors.borderSubtle,
    );
  }

  Widget _buildModeButton(BuildContext context, IconData icon, String label, CanvasDrawMode mode) {
    final colors = context.colors;
    final isActive = _drawMode == mode;
    return InkWell(
      onTap: () => setState(() => _drawMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? colors.accentPrimary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? colors.accentPrimary : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isActive ? colors.accentPrimary : colors.fgSecondary),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 10, color: isActive ? colors.accentPrimary : colors.fgSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(BuildContext context, IconData icon, String tooltip, VoidCallback? onTap) {
    final colors = context.colors;
    final isEnabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: isEnabled ? colors.fgPrimary : colors.fgSecondary.withValues(alpha: 0.4)),
        ),
      ),
    );
  }

  // --- Grid Cell Card ---

  Widget _buildGridCellCard(BuildContext context, CanvasGridCell cell) {
    final colors = context.colors;
    final rect = cell.rect;
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (!_isShiftPressed) {
              for (final c in widget.gridCells) {
                c.isSelected = false;
              }
            }
            cell.isSelected = !cell.isSelected;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cell.isSelected ? colors.accentPrimary : colors.borderSubtle,
              width: cell.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: cell.isSelected
                ? [BoxShadow(color: colors.accentPrimary.withValues(alpha: 0.2), blurRadius: 10)]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accentEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(cell.diagramType, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.accentEmerald)),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: "Attach Diagram to AI Chat (@)",
                    child: InkWell(
                      onTap: () => widget.onAttachDiagramToChat(cell),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.bgCanvas,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Text('@', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.accentPrimary)),
                            const SizedBox(width: 2),
                            Text('Attach', style: TextStyle(fontSize: 9, color: colors.fgPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(cell.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
              Divider(color: colors.borderSubtle, height: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: cell.nodeLabels.map((lbl) {
                    return Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: colors.accentPrimary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(lbl, style: TextStyle(fontSize: 11, color: colors.fgSecondary))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Movable Object Card ---

  Widget _buildMovableObjectCard(BuildContext context, CanvasObject obj) {
    final colors = context.colors;
    return Positioned(
      left: obj.position.dx,
      top: obj.position.dy,
      width: obj.size.width,
      height: obj.size.height,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (!_isShiftPressed) {
              for (final o in widget.customObjects) {
                o.isSelected = false;
              }
            }
            obj.isSelected = !obj.isSelected;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            obj.position += details.delta;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: obj.isSelected ? colors.accentEmerald : colors.borderSubtle,
              width: obj.isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              obj.label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.fgPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Grid Lines Background Painter (mat effect) ---
class CanvasGridBackgroundPainter extends CustomPainter {
  final AppColorsExtension? colors;

  CanvasGridBackgroundPainter({this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final gridLineColor = colors != null
        ? colors!.borderSubtle.withValues(alpha: 0.5)
        : AppColors.borderSubtle.withValues(alpha: 0.4);

    final paint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 0.5;
    const double step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasGridBackgroundPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

// --- Drawing Overlay Painter (pen strokes only — no eraser strokes) ---
class DrawingOverlayPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentWidth;

  DrawingOverlayPainter({
    required this.paths,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final p = ui.Path();
      if (path.points.isNotEmpty) {
        p.moveTo(path.points.first.dx, path.points.first.dy);
        for (int i = 1; i < path.points.length; i++) {
          p.lineTo(path.points[i].dx, path.points[i].dy);
        }
      }
      canvas.drawPath(p, paint);
    }

    // Current active stroke preview
    if (currentStroke.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final p = ui.Path();
      p.moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        p.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
