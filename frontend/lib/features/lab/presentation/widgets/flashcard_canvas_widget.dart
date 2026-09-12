import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/flashcard_model.dart';
import 'bounded_grid_canvas_widget.dart';

enum CanvasViewFilter { all, due, mastered, tagged }
enum AutoLayoutMode { grid, leitner, free }

class FlashcardCanvasWidget extends StatefulWidget {
  final List<FlashcardItem> cards;
  final ValueChanged<FlashcardItem>? onAttachCardToChat;
  final VoidCallback? onBackToDeck;

  const FlashcardCanvasWidget({
    super.key,
    required this.cards,
    this.onAttachCardToChat,
    this.onBackToDeck,
  });

  @override
  State<FlashcardCanvasWidget> createState() => _FlashcardCanvasWidgetState();
}

class _FlashcardCanvasWidgetState extends State<FlashcardCanvasWidget> {
  CanvasViewFilter _filter = CanvasViewFilter.all;
  AutoLayoutMode _layoutMode = AutoLayoutMode.free;
  final TransformationController _transformationController = TransformationController();

  final List<FlashcardConnection> _connections = [];
  String? _connectSourceCardId;
  bool _isConnectingMode = false;

  late List<FlashcardItem> _canvasCards;

  @override
  void initState() {
    super.initState();
    _canvasCards = List.from(widget.cards);
    _applyAutoLayout(AutoLayoutMode.grid);
  }

  @override
  void didUpdateWidget(FlashcardCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards != widget.cards) {
      _canvasCards = List.from(widget.cards);
      _applyAutoLayout(_layoutMode);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _applyAutoLayout(AutoLayoutMode mode) {
    setState(() {
      _layoutMode = mode;
      if (mode == AutoLayoutMode.grid) {
        const double startX = 60;
        const double startY = 60;
        const double spacingX = 310;
        const double spacingY = 190;
        const int cols = 3;

        for (int i = 0; i < _canvasCards.length; i++) {
          final row = i ~/ cols;
          final col = i % cols;
          _canvasCards[i].position = Offset(startX + col * spacingX, startY + row * spacingY);
        }
      } else if (mode == AutoLayoutMode.leitner) {
        const double boxSpacingX = 340;
        for (int i = 0; i < _canvasCards.length; i++) {
          final box = _canvasCards[i].leitnerBox;
          final countInBox = _canvasCards.take(i).where((c) => c.leitnerBox == box).length;
          _canvasCards[i].position = Offset(60 + (box - 1) * boxSpacingX, 60 + countInBox * 180);
        }
      }
    });
  }

  void _handleCardTap(FlashcardItem card) {
    if (_isConnectingMode) {
      if (_connectSourceCardId == null) {
        setState(() => _connectSourceCardId = card.id);
      } else if (_connectSourceCardId != card.id) {
        setState(() {
          _connections.add(FlashcardConnection(
            fromCardId: _connectSourceCardId!,
            toCardId: card.id,
            label: 'Prerequisite',
          ));
          _connectSourceCardId = null;
          _isConnectingMode = false;
        });
      }
    }
  }

  List<FlashcardItem> get _filteredCards {
    switch (_filter) {
      case CanvasViewFilter.due:
        return _canvasCards.where((c) => c.isDue).toList();
      case CanvasViewFilter.mastered:
        return _canvasCards.where((c) => c.easeFactor > 2.5).toList();
      case CanvasViewFilter.tagged:
        return _canvasCards.where((c) => c.tags.isNotEmpty).toList();
      case CanvasViewFilter.all:
        return _canvasCards;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        _buildHeaderToolbar(context),
        _buildLeitnerDistributionBar(context),
        Expanded(
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(2000),
                minScale: 0.2,
                maxScale: 2.5,
                constrained: false,
                child: SizedBox(
                  width: 3200,
                  height: 2400,
                  child: CustomPaint(
                    painter: CanvasGridBackgroundPainter(colors: colors),
                    foregroundPainter: FlashcardConnectionPainter(
                      connections: _connections,
                      cards: _canvasCards,
                      color: colors.accentEmerald,
                    ),
                    child: Stack(
                      children: [
                        for (final card in _filteredCards) _buildCanvasCard(card),
                      ],
                    ),
                  ),
                ),
              ),
              _buildMinimap(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderToolbar(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgActivityBar,
        border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          if (widget.onBackToDeck != null) ...[
            InkWell(
              onTap: widget.onBackToDeck,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgCanvas,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.undo_rounded, size: 12, color: colors.fgPrimary),
                    const SizedBox(width: 4),
                    Text('Back to Deck', style: TextStyle(fontSize: 11, color: colors.fgPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          Icon(Icons.grid_4x4_rounded, size: 15, color: colors.accentEmerald),
          const SizedBox(width: 6),
          Text('Flashcard Canvas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
          const SizedBox(width: 16),

          _buildFilterChip(context, 'All', CanvasViewFilter.all),
          const SizedBox(width: 4),
          _buildFilterChip(context, 'Due Review', CanvasViewFilter.due),
          const SizedBox(width: 4),
          _buildFilterChip(context, 'Mastered', CanvasViewFilter.mastered),

          const Spacer(),

          InkWell(
            onTap: () {
              setState(() {
                _isConnectingMode = !_isConnectingMode;
                _connectSourceCardId = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isConnectingMode ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgCanvas,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _isConnectingMode ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.polyline_rounded, size: 12, color: _isConnectingMode ? colors.accentPrimary : colors.fgSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _isConnectingMode ? 'Click 2 cards...' : 'Connect Cards',
                    style: TextStyle(fontSize: 11, color: _isConnectingMode ? colors.accentPrimary : colors.fgPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          PopupMenuButton<AutoLayoutMode>(
            position: PopupMenuPosition.under,
            color: colors.bgElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colors.borderSubtle),
            ),
            onSelected: _applyAutoLayout,
            itemBuilder: (context) => [
              PopupMenuItem(value: AutoLayoutMode.grid, child: Text('Grid Layout', style: TextStyle(fontSize: 11, color: colors.fgPrimary))),
              PopupMenuItem(value: AutoLayoutMode.leitner, child: Text('Leitner Box Layout', style: TextStyle(fontSize: 11, color: colors.fgPrimary))),
              PopupMenuItem(value: AutoLayoutMode.free, child: Text('Free Drag Layout', style: TextStyle(fontSize: 11, color: colors.fgPrimary))),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgCanvas,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_mosaic_rounded, size: 12, color: colors.fgSecondary),
                  const SizedBox(width: 4),
                  Text('Auto Layout', style: TextStyle(fontSize: 11, color: colors.fgPrimary)),
                  Icon(Icons.arrow_drop_down, size: 14, color: colors.fgSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, CanvasViewFilter filter) {
    final colors = context.colors;
    final isSelected = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentEmerald.withValues(alpha: 0.15) : colors.bgCanvas,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? colors.accentEmerald : colors.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colors.accentEmerald : colors.fgSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasCard(FlashcardItem card) {
    final isSelectedForConnection = _connectSourceCardId == card.id;

    return Positioned(
      left: card.position.dx,
      top: card.position.dy,
      width: 280,
      height: 160,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (_layoutMode == AutoLayoutMode.free) {
            setState(() {
              card.position += details.delta;
            });
          }
        },
        child: SpringCanvasFlipCard(
          card: card,
          isSelectedForConnection: isSelectedForConnection,
          onCardTap: () => _handleCardTap(card),
          onAttachCardToChat: widget.onAttachCardToChat,
        ),
      ),
    );
  }

  Widget _buildLeitnerDistributionBar(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      color: colors.bgCanvas.withValues(alpha: 0.6),
      child: Row(
        children: [
          Text('Leitner Box Distribution: ', style: TextStyle(fontSize: 10, color: colors.fgSecondary)),
          for (int box = 1; box <= 5; box++) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Text(
                'Box $box: ${_canvasCards.where((c) => c.leitnerBox == box).length}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.accentEmerald),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimap(BuildContext context) {
    final colors = context.colors;

    return Positioned(
      right: 16,
      bottom: 16,
      child: Container(
        width: 140,
        height: 100,
        decoration: BoxDecoration(
          color: colors.bgElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: CustomPaint(
          painter: MinimapPainter(cards: _filteredCards, color: colors.accentEmerald),
        ),
      ),
    );
  }
}

// ============================================================================
// --- Spring Canvas Flip Card (3D Flip + Spring Physics for Canvas Cards) ---
// ============================================================================

class SpringCanvasFlipCard extends StatefulWidget {
  final FlashcardItem card;
  final bool isSelectedForConnection;
  final VoidCallback onCardTap;
  final ValueChanged<FlashcardItem>? onAttachCardToChat;

  const SpringCanvasFlipCard({
    super.key,
    required this.card,
    required this.isSelectedForConnection,
    required this.onCardTap,
    this.onAttachCardToChat,
  });

  @override
  State<SpringCanvasFlipCard> createState() => _SpringCanvasFlipCardState();
}

class _SpringCanvasFlipCardState extends State<SpringCanvasFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flipAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeOutBack),
    );

    if (widget.card.isFlipped) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SpringCanvasFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.card.isFlipped != oldWidget.card.isFlipped) {
      if (widget.card.isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onCardTap();
    setState(() {
      widget.card.isFlipped = !widget.card.isFlipped;
      if (widget.card.isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value;
        final isBack = angle > math.pi / 2;

        final progress = (angle / math.pi).clamp(0.0, 1.0);
        final liftFactor = 1.0 - (2.0 * (progress - 0.5)).abs();
        final shadowBlur = 8.0 + (16.0 * liftFactor);
        final shadowOffsetY = 4.0 + (12.0 * liftFactor);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              decoration: BoxDecoration(
                color: isBack
                    ? colors.accentEmerald.withValues(alpha: 0.08)
                    : colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isSelectedForConnection
                      ? colors.accentPrimary
                      : isBack
                          ? colors.accentEmerald
                          : widget.card.confidenceColor,
                  width: widget.isSelectedForConnection ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isBack ? colors.accentEmerald : widget.card.confidenceColor)
                        .withValues(alpha: 0.15 + (0.2 * liftFactor)),
                    blurRadius: shadowBlur,
                    offset: Offset(0, shadowOffsetY),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: isBack
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(math.pi),
                        alignment: Alignment.center,
                        child: _buildBackContent(context),
                      )
                    : _buildFrontContent(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrontContent(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: widget.card.confidenceColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(widget.card.confidenceLabel, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: widget.card.confidenceColor)),
            ),
            const SizedBox(width: 4),
            Text(widget.card.topicTag, style: TextStyle(fontSize: 9, color: colors.fgSecondary)),
            const Spacer(),
            if (widget.onAttachCardToChat != null)
              InkWell(
                onTap: () => widget.onAttachCardToChat!(widget.card),
                child: Icon(Icons.alternate_email_rounded, size: 13, color: colors.accentPrimary),
              ),
          ],
        ),
        Divider(color: colors.borderSubtle, height: 10),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Text(
                widget.card.front,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Interval: ${widget.card.intervalDays}d', style: TextStyle(fontSize: 8, color: colors.fgSecondary)),
            Text('Tap to flip', style: TextStyle(fontSize: 8, color: colors.fgSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildBackContent(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: colors.accentEmerald.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('ANSWER', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colors.accentEmerald)),
            ),
            const SizedBox(width: 4),
            Text(widget.card.topicTag, style: TextStyle(fontSize: 9, color: colors.accentEmerald)),
          ],
        ),
        Divider(color: colors.borderSubtle, height: 10),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Text(
                widget.card.back,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: colors.fgPrimary, height: 1.3),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Interval: ${widget.card.intervalDays}d', style: TextStyle(fontSize: 8, color: colors.fgSecondary)),
            Text('Tap to flip back', style: TextStyle(fontSize: 8, color: colors.accentEmerald)),
          ],
        ),
      ],
    );
  }
}

class FlashcardConnection {
  final String fromCardId;
  final String toCardId;
  final String label;

  FlashcardConnection({
    required this.fromCardId,
    required this.toCardId,
    required this.label,
  });
}

class FlashcardConnectionPainter extends CustomPainter {
  final List<FlashcardConnection> connections;
  final List<FlashcardItem> cards;
  final Color color;

  FlashcardConnectionPainter({
    required this.connections,
    required this.cards,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final conn in connections) {
      final fromCard = cards.firstWhere((c) => c.id == conn.fromCardId, orElse: () => cards.first);
      final toCard = cards.firstWhere((c) => c.id == conn.toCardId, orElse: () => cards.first);

      final start = Offset(fromCard.position.dx + 140, fromCard.position.dy + 80);
      final end = Offset(toCard.position.dx + 140, toCard.position.dy + 80);

      final path = Path();
      path.moveTo(start.dx, start.dy);

      final controlPoint1 = Offset(start.dx + (end.dx - start.dx) / 2, start.dy);
      final controlPoint2 = Offset(start.dx + (end.dx - start.dx) / 2, end.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, end.dx, end.dy);

      canvas.drawPath(path, paint);
      canvas.drawCircle(start, 4, dotPaint);
      canvas.drawCircle(end, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FlashcardConnectionPainter oldDelegate) => true;
}

class MinimapPainter extends CustomPainter {
  final List<FlashcardItem> cards;
  final Color color;

  MinimapPainter({required this.cards, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double canvasW = 3200;
    const double canvasH = 2400;

    final scaleX = size.width / canvasW;
    final scaleY = size.height / canvasH;

    final cardPaint = Paint()..color = color.withValues(alpha: 0.8);

    for (final card in cards) {
      final rect = Rect.fromLTWH(
        card.position.dx * scaleX,
        card.position.dy * scaleY,
        280 * scaleX,
        160 * scaleY,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), cardPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) => true;
}
