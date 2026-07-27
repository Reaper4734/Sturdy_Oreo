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
  Color _penColor = AppColors.accentPrimary;
  double _penStrokeWidth = 2.5;
  double _penOpacity = 1.0;
  double _eraserRadius = 16.0;
  List<Offset> _currentStrokePoints = [];

  // Undo / Redo stacks
  final List<DrawingPath> _undoStack = [];

  static const List<Color> _colorPalette = [
    AppColors.accentPrimary,
    AppColors.accentEmerald,
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Colors.white,
  ];

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

  // --- Drawing Handlers (with coordinate fix) ---

  void _onPointerDown(PointerDownEvent event) {
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

  void _onPointerUp(PointerUpEvent event) {
    if (_drawMode == CanvasDrawMode.pen && _currentStrokePoints.isNotEmpty) {
      final effectiveColor = _penColor.withValues(alpha: _penOpacity);
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
    final canvasSize = _calculateCanvasBounds();
    final isDrawing = _drawMode == CanvasDrawMode.pen || _drawMode == CanvasDrawMode.eraser;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCanvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            // Canvas Header Toolbar
            _buildToolbar(),

            // Canvas Area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: Listener(
                  onPointerDown: isDrawing ? _onPointerDown : null,
                  onPointerMove: isDrawing ? _onPointerMove : null,
                  onPointerUp: isDrawing ? _onPointerUp : null,
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
                        painter: CanvasGridBackgroundPainter(),
                        foregroundPainter: DrawingOverlayPainter(
                          paths: widget.drawingPaths,
                          currentStroke: _currentStrokePoints,
                          currentColor: _penColor.withValues(alpha: _penOpacity),
                          currentWidth: _penStrokeWidth,
                        ),
                        child: SizedBox(
                          width: canvasSize.width,
                          height: canvasSize.height,
                          child: Stack(
                            children: [
                              ...widget.gridCells.map((cell) => _buildGridCellCard(cell)),
                              ...widget.customObjects.map((obj) => _buildMovableObjectCard(obj)),
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

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: AppColors.bgActivityBar,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.grid_4x4_rounded, size: 14, color: AppColors.accentEmerald),
          const SizedBox(width: 6),
          const Text('Canvas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
          const SizedBox(width: 10),

          // Divider
          _toolDivider(),

          // Mode Tools
          _buildModeButton(Icons.near_me_outlined, 'Select', CanvasDrawMode.select),
          const SizedBox(width: 3),
          _buildModeButton(Icons.edit_rounded, 'Pen', CanvasDrawMode.pen),
          const SizedBox(width: 3),
          _buildModeButton(Icons.auto_fix_high_rounded, 'Eraser', CanvasDrawMode.eraser),

          const SizedBox(width: 6),
          _toolDivider(),

          // Pen options (color palette + stroke width + opacity) — only when pen active
          if (_drawMode == CanvasDrawMode.pen) ...[
            const SizedBox(width: 4),
            ..._colorPalette.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: InkWell(
                    onTap: () => setState(() => _penColor = c),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == _penColor ? Colors.white : AppColors.borderSubtle,
                          width: c == _penColor ? 2 : 1,
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
                    activeTrackColor: AppColors.accentPrimary,
                    inactiveTrackColor: AppColors.borderSubtle,
                    thumbColor: AppColors.accentPrimary,
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
            _toolDivider(),

            // Opacity
            Tooltip(
              message: 'Opacity: ${(_penOpacity * 100).toInt()}%',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.opacity_rounded, size: 12, color: AppColors.fgSecondary),
                  SizedBox(
                    width: 46,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        activeTrackColor: AppColors.accentEmerald,
                        inactiveTrackColor: AppColors.borderSubtle,
                        thumbColor: AppColors.accentEmerald,
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
                  const Text('Size', style: TextStyle(fontSize: 10, color: AppColors.fgSecondary)),
                  SizedBox(
                    width: 60,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        activeTrackColor: AppColors.accentPrimary,
                        inactiveTrackColor: AppColors.borderSubtle,
                        thumbColor: AppColors.accentPrimary,
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
            Icons.undo_rounded,
            'Undo (Ctrl+Z)',
            widget.drawingPaths.isNotEmpty ? _undo : null,
          ),
          // Redo
          _buildActionIcon(
            Icons.redo_rounded,
            'Redo (Ctrl+Shift+Z)',
            _undoStack.isNotEmpty ? _redo : null,
          ),
          const SizedBox(width: 2),
          // Clear
          _buildActionIcon(
            Icons.delete_outline_rounded,
            'Clear All',
            widget.drawingPaths.isNotEmpty ? _clearAll : null,
          ),

          // Toggle to Transcript (when inline below video)
          if (widget.onToggleToTranscript != null) ...[
            const SizedBox(width: 6),
            _toolDivider(),
            const SizedBox(width: 6),
            InkWell(
              onTap: widget.onToggleToTranscript,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgCanvas,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.style_outlined, size: 12, color: AppColors.accentEmerald),
                    SizedBox(width: 4),
                    Text('Show Flashcards', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentEmerald)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolDivider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.borderSubtle,
    );
  }

  Widget _buildModeButton(IconData icon, String label, CanvasDrawMode mode) {
    final isActive = _drawMode == mode;
    return InkWell(
      onTap: () => setState(() => _drawMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentPrimary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? AppColors.accentPrimary : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isActive ? AppColors.accentPrimary : AppColors.fgSecondary),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 10, color: isActive ? AppColors.accentPrimary : AppColors.fgSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String tooltip, VoidCallback? onTap) {
    final isEnabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: isEnabled ? AppColors.fgPrimary : AppColors.fgSecondary.withValues(alpha: 0.4)),
        ),
      ),
    );
  }

  // --- Grid Cell Card ---

  Widget _buildGridCellCard(CanvasGridCell cell) {
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
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cell.isSelected ? AppColors.accentPrimary : AppColors.borderSubtle,
              width: cell.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: cell.isSelected
                ? [BoxShadow(color: AppColors.accentPrimary.withValues(alpha: 0.2), blurRadius: 10)]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(cell.diagramType, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accentEmerald)),
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
                          color: AppColors.bgCanvas,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: const [
                            Text('@', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentPrimary)),
                            SizedBox(width: 2),
                            Text('Attach', style: TextStyle(fontSize: 9, color: AppColors.fgPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(cell.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
              const Divider(color: AppColors.borderSubtle, height: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: cell.nodeLabels.map((lbl) {
                    return Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: AppColors.accentPrimary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(lbl, style: const TextStyle(fontSize: 11, color: AppColors.fgSecondary))),
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

  Widget _buildMovableObjectCard(CanvasObject obj) {
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
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: obj.isSelected ? AppColors.accentEmerald : AppColors.borderSubtle,
              width: obj.isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              obj.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Grid Lines Background Painter (mat effect) ---
class CanvasGridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.4)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
