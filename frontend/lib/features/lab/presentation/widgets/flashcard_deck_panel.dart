import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/flashcard_model.dart';
import 'bounded_grid_canvas_widget.dart';

class FlashcardDeckPanel extends StatefulWidget {
  final List<FlashcardItem> cards;
  final String topicTag;
  final bool isScrollMode;
  final ValueChanged<FlashcardItem> onAttachCardToChat;
  final VoidCallback onToggleToCanvas;
  final Function(String cardId, int quality)? onReviewCard;

  const FlashcardDeckPanel({
    super.key,
    required this.cards,
    required this.topicTag,
    this.isScrollMode = false,
    required this.onAttachCardToChat,
    required this.onToggleToCanvas,
    this.onReviewCard,
  });

  @override
  State<FlashcardDeckPanel> createState() => _FlashcardDeckPanelState();
}

class _FlashcardDeckPanelState extends State<FlashcardDeckPanel> {
  int _currentIndex = 0; // Card index for 1x1 split mode
  bool _isMovingForward = true; // Tracks swipe direction (Next = true, Prev = false)
  StudyMode _studyMode = StudyMode.browse;

  int _streakCount = 0;
  final FocusNode _keyboardFocusNode = FocusNode();
  List<FlashcardItem> _activeCards = [];

  @override
  void initState() {
    super.initState();
    _activeCards = List.from(widget.cards);
  }

  @override
  void didUpdateWidget(FlashcardDeckPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards != widget.cards) {
      _activeCards = List.from(widget.cards);
      if (_currentIndex >= _activeCards.length) {
        _currentIndex = 0;
      }
    }
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  FlashcardItem? get _currentCard =>
      _activeCards.isNotEmpty && _currentIndex < _activeCards.length ? _activeCards[_currentIndex] : null;

  void _nextCard() {
    if (_activeCards.isEmpty) return;
    setState(() {
      _isMovingForward = true;
      if (_currentCard != null && _currentCard!.isFlipped) {
        _currentCard!.isFlipped = false;
      }
      _currentIndex = (_currentIndex + 1) % _activeCards.length;
    });
  }

  void _prevCard() {
    if (_activeCards.isEmpty) return;
    setState(() {
      _isMovingForward = false;
      if (_currentCard != null && _currentCard!.isFlipped) {
        _currentCard!.isFlipped = false;
      }
      _currentIndex = (_currentIndex - 1 + _activeCards.length) % _activeCards.length;
    });
  }

  void _handleReview(FlashcardItem card, int quality) {
    if (widget.onReviewCard != null) {
      widget.onReviewCard!(card.id, quality);
    }

    if (quality >= 4) {
      _streakCount += 1;
    } else {
      _streakCount = 0;
    }

    if (!widget.isScrollMode) {
      _nextCard();
    } else {
      setState(() {});
    }
  }

  void _handleModeChange(StudyMode newMode) {
    setState(() {
      _studyMode = newMode;
      if (_studyMode == StudyMode.shuffle) {
        _activeCards.shuffle();
      } else {
        _activeCards = List.from(widget.cards);
      }
      _currentIndex = 0;
    });
  }

  double get _masteryRatio {
    if (_activeCards.isEmpty) return 0.0;
    final masteredCount = _activeCards.where((c) => c.easeFactor > 2.5).length;
    return masteredCount / _activeCards.length;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_activeCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Center(
          child: Text('No flashcards available for this topic.', style: TextStyle(color: colors.fgSecondary)),
        ),
      );
    }

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {},
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            // --- Header Bar ---
            _buildHeader(context),

            // --- Stats Bar ---
            _buildStatsBar(context),

            // --- Mat Background Viewport ---
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: CustomPaint(
                  painter: CanvasGridBackgroundPainter(colors: colors),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: widget.isScrollMode ? _build2x2Grid() : _build1x1SplitCard(),
                  ),
                ),
              ),
            ),

            // --- Footer Controls for 1x1 Split Mode ---
            if (!widget.isScrollMode && _currentCard != null) _build1x1FooterControls(context, _currentCard!),
          ],
        ),
      ),
    );
  }

  // --- 1x1 Split Mode with Full-Viewport Canvas Swipe Page Transition ---

  Widget _build1x1SplitCard() {
    final card = _currentCard!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        const cardWidth = 580.0;

        final offsetMultiplier = viewportWidth > 0
            ? (viewportWidth / math.min(viewportWidth, cardWidth))
            : 2.0;

        return ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final isCurrentKey = (child.key as ValueKey<String>?)?.value == card.id;
              final inOffset = _isMovingForward
                  ? Offset(offsetMultiplier, 0.0)
                  : Offset(-offsetMultiplier, 0.0);
              final outOffset = _isMovingForward
                  ? Offset(-offsetMultiplier, 0.0)
                  : Offset(offsetMultiplier, 0.0);

              final offsetAnimation = Tween<Offset>(
                begin: isCurrentKey ? inOffset : outOffset,
                end: Offset.zero,
              ).animate(animation);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<String>(card.id),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: cardWidth),
                    child: Spring3DFlipCard(
                      card: card,
                      isScrollMode: false,
                      onAttachCardToChat: widget.onAttachCardToChat,
                      onReviewCard: (q) => _handleReview(card, q),
                      onFlipChanged: () => setState(() {}),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 2x2 Scroll Mode Grid (4 cards in 2x2 grid) ---

  Widget _build2x2Grid() {
    final visibleCards = _activeCards.take(4).toList();

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Spring3DFlipCard(
                  card: visibleCards[0],
                  isScrollMode: true,
                  onAttachCardToChat: widget.onAttachCardToChat,
                  onReviewCard: (q) => _handleReview(visibleCards[0], q),
                  onFlipChanged: () => setState(() {}),
                ),
              ),
              if (visibleCards.length > 1) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Spring3DFlipCard(
                    card: visibleCards[1],
                    isScrollMode: true,
                    onAttachCardToChat: widget.onAttachCardToChat,
                    onReviewCard: (q) => _handleReview(visibleCards[1], q),
                    onFlipChanged: () => setState(() {}),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (visibleCards.length > 2) ...[
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Spring3DFlipCard(
                    card: visibleCards[2],
                    isScrollMode: true,
                    onAttachCardToChat: widget.onAttachCardToChat,
                    onReviewCard: (q) => _handleReview(visibleCards[2], q),
                    onFlipChanged: () => setState(() {}),
                  ),
                ),
                if (visibleCards.length > 3) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Spring3DFlipCard(
                      card: visibleCards[3],
                      isScrollMode: true,
                      onAttachCardToChat: widget.onAttachCardToChat,
                      onReviewCard: (q) => _handleReview(visibleCards[3], q),
                      onFlipChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- Header ---

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    final modeLabel = _studyMode == StudyMode.browse
        ? 'Browse'
        : _studyMode == StudyMode.quiz
            ? 'Quiz'
            : 'Shuffle';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgActivityBar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          Icon(Icons.style_outlined, size: 15, color: colors.accentEmerald),
          const SizedBox(width: 6),
          Text(
            'Flashcards · ${widget.topicTag}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary),
          ),
          const SizedBox(width: 10),

          // Clean Popup Menu (Opens Below Button, No Overlap)
          PopupMenuButton<StudyMode>(
            position: PopupMenuPosition.under,
            color: colors.bgElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: colors.borderSubtle),
            ),
            elevation: 8,
            onSelected: _handleModeChange,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: StudyMode.browse,
                height: 36,
                child: Text('Browse', style: TextStyle(fontSize: 12, color: colors.fgPrimary)),
              ),
              PopupMenuItem(
                value: StudyMode.quiz,
                height: 36,
                child: Text('Quiz', style: TextStyle(fontSize: 12, color: colors.fgPrimary)),
              ),
              PopupMenuItem(
                value: StudyMode.shuffle,
                height: 36,
                child: Text('Shuffle', style: TextStyle(fontSize: 12, color: colors.fgPrimary)),
              ),
            ],
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
                  Text(modeLabel, style: TextStyle(fontSize: 11, color: colors.fgPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 14, color: colors.fgSecondary),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Show Canvas Toggle
          InkWell(
            onTap: widget.onToggleToCanvas,
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
                  Icon(Icons.grid_4x4_rounded, size: 12, color: colors.accentPrimary),
                  const SizedBox(width: 4),
                  Text('Show Canvas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.accentPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Stats Bar ---

  Widget _buildStatsBar(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: colors.bgCanvas.withValues(alpha: 0.6),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 4),
          Text('$_streakCount streak', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
          const SizedBox(width: 16),

          Text('Mastery', style: TextStyle(fontSize: 10, color: colors.fgSecondary)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _masteryRatio,
                minHeight: 5,
                backgroundColor: colors.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accentEmerald),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(_masteryRatio * 100).toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.accentEmerald)),
        ],
      ),
    );
  }

  // --- Footer Controls for 1x1 Split Mode (Ratings on Bottom Right ONLY) ---

  Widget _build1x1FooterControls(BuildContext context, FlashcardItem card) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgActivityBar,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(top: BorderSide(color: colors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          // Left side: Paging Navigation
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            color: colors.fgPrimary,
            onPressed: _prevCard,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          Text(
            '${_currentIndex + 1} / ${_activeCards.length}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.fgPrimary),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            color: colors.fgPrimary,
            onPressed: _nextCard,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          const Spacer(),

          // Right Side: Rating Buttons ONLY for Split Mode
          if (card.isFlipped) ...[
            _buildQualityBtn('Hard', 3, Colors.orange, Icons.sentiment_dissatisfied_rounded, card),
            const SizedBox(width: 6),
            _buildQualityBtn('Good', 4, colors.accentEmerald, Icons.sentiment_satisfied_alt_rounded, card),
            const SizedBox(width: 6),
            _buildQualityBtn('Perfect', 5, colors.accentPrimary, Icons.stars_rounded, card),
          ] else ...[
            InkWell(
              onTap: () => widget.onAttachCardToChat(card),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgCanvas,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alternate_email_rounded, size: 12, color: colors.accentPrimary),
                    const SizedBox(width: 4),
                    Text('Attach to Chat', style: TextStyle(fontSize: 11, color: colors.fgPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityBtn(String label, int quality, Color color, IconData icon, FlashcardItem card) {
    return InkWell(
      onTap: () => _handleReview(card, quality),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// --- Spring 3D Flip Card Widget (Adaptive Layout - Zero Overflow Guarantee) ---
// ============================================================================

class Spring3DFlipCard extends StatefulWidget {
  final FlashcardItem card;
  final bool isScrollMode;
  final ValueChanged<FlashcardItem> onAttachCardToChat;
  final ValueChanged<int> onReviewCard;
  final VoidCallback onFlipChanged;

  const Spring3DFlipCard({
    super.key,
    required this.card,
    required this.isScrollMode,
    required this.onAttachCardToChat,
    required this.onReviewCard,
    required this.onFlipChanged,
  });

  @override
  State<Spring3DFlipCard> createState() => _Spring3DFlipCardState();
}

class _Spring3DFlipCardState extends State<Spring3DFlipCard> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(Spring3DFlipCard oldWidget) {
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
    setState(() {
      widget.card.isFlipped = !widget.card.isFlipped;
      if (widget.card.isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    });
    widget.onFlipChanged();
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
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isBack
                    ? colors.accentEmerald.withValues(alpha: 0.08)
                    : colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBack ? colors.accentEmerald : widget.card.confidenceColor,
                  width: 1.5,
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
              child: isBack
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: _buildCardBack(context),
                    )
                  : _buildCardFront(context),
            ),
          ),
        );
      },
    );
  }

  // --- Front Side (Question) ---

  Widget _buildCardFront(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxHeight < 110;
        final isTiny = constraints.maxHeight < 75;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isTiny)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: widget.card.confidenceColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(widget.card.confidenceLabel, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: widget.card.confidenceColor)),
                  ),
                  const SizedBox(width: 4),
                  Text(widget.card.topicTag, style: TextStyle(fontSize: 9, color: colors.fgSecondary)),
                  const Spacer(),
                  InkWell(
                    onTap: () => widget.onAttachCardToChat(widget.card),
                    child: Icon(Icons.alternate_email_rounded, size: 13, color: colors.accentPrimary),
                  ),
                ],
              ),
            
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.card.type == FlashcardType.codeSnippet) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors.bgElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: Text(
                            widget.card.front,
                            style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: colors.accentEmerald),
                          ),
                        ),
                      ] else ...[
                        Text(
                          widget.card.front,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: widget.isScrollMode ? 11 : (isSmall ? 11 : 13),
                            fontWeight: FontWeight.bold,
                            color: colors.fgPrimary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            if (!isSmall)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Question', style: TextStyle(fontSize: 8, color: colors.fgSecondary)),
                  Text('Tap to flip', style: TextStyle(fontSize: 8, color: colors.accentPrimary)),
                ],
              ),
          ],
        );
      },
    );
  }

  // --- Back Side (Answer) ---

  Widget _buildCardBack(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxHeight < 110;
        final isTiny = constraints.maxHeight < 75;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isTiny)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.accentEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('ANSWER & EXPLANATION', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colors.accentEmerald)),
                  ),
                  const Spacer(),
                  Text('Interval: ${widget.card.intervalDays}d', style: TextStyle(fontSize: 8, color: colors.fgSecondary)),
                ],
              ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Text(
                    widget.card.back,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widget.isScrollMode ? 11 : (isSmall ? 11 : 12),
                      color: colors.fgPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),

            if (widget.isScrollMode) ...[
              if (!isSmall)
                Row(
                  children: [
                    _buildQualityBtn('Hard', 3, Colors.orange),
                    const SizedBox(width: 4),
                    _buildQualityBtn('Good', 4, colors.accentEmerald),
                    const SizedBox(width: 4),
                    _buildQualityBtn('Perfect', 5, colors.accentPrimary),
                  ],
                ),
            ] else ...[
              if (!isSmall)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Answer Revealed', style: TextStyle(fontSize: 8, color: colors.accentEmerald)),
                    Text('Rate quality in bottom right →', style: TextStyle(fontSize: 8, color: colors.fgSecondary)),
                  ],
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQualityBtn(String label, int quality, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () => widget.onReviewCard(quality),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 0.8),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
    );
  }
}
