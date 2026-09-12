import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/models/roadmap_model.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../../shared/models/mastery_test_model.dart';
import '../../../shared/models/learning_lab_model.dart';
import '../../../shared/providers/workspace_providers.dart';
import '../../../shared/repositories/http_mastery_test_repository.dart';
import '../../survey/presentation/widgets/long_mcq_survey_layout.dart';
import '../../survey/presentation/widgets/code_terminal_challenge_layout.dart';
import '../../survey/presentation/widgets/popup_questionnaire_layout.dart';
import '../../workspace/data/http_workspace_repository.dart';
import '../data/http_flashcard_repository.dart';
import 'widgets/bounded_grid_canvas_widget.dart';
import 'widgets/flashcard_deck_panel.dart';
import 'widgets/learning_lab_sidebar.dart';
import 'widgets/video_player_panel.dart';
import '../../../shared/repositories/http_ingestion_repository.dart';

class LearningLabWorkspaceScreen extends ConsumerStatefulWidget {
  final String? activeNodeTitle;
  final VoidCallback? onUndoBackToMindMap;
  final List<CanvasGridCell> sharedCanvasCells;
  final List<CanvasObject> sharedCanvasObjects;
  final List<DrawingPath> sharedDrawingPaths;
  final bool isEmbedded;

  const LearningLabWorkspaceScreen({
    super.key,
    this.activeNodeTitle,
    this.onUndoBackToMindMap,
    required this.sharedCanvasCells,
    required this.sharedCanvasObjects,
    required this.sharedDrawingPaths,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<LearningLabWorkspaceScreen> createState() => _LearningLabWorkspaceScreenState();
}

class _LearningLabWorkspaceScreenState extends ConsumerState<LearningLabWorkspaceScreen> {
  List<QuestionItem>? _topicAssessments;

  List<FlashcardItem> _topicFlashcards = [];
  List<Map<String, dynamic>> _topicVideos = [];
  bool _isLoading = true;
  String? _dismissedQuizForContext;

  int _currentTimestampSeconds = 342;
  bool _showFlashcards = true; // true = flashcards deck, false = drawing canvas
  bool _isScrollMode = false; // false = split view (resizable), true = full scroll view
  double _chatPanelWidth = 360.0;
  double _videoFraction = 0.70; // Video takes 70%, flashcards/canvas takes 30% in split mode

  @override
  void initState() {
    super.initState();
    _loadData();
    final activeWs = ref.read(activeWorkspaceProvider);
    if (activeWs != null) {
      _currentTimestampSeconds = activeWs.videoTimestampSeconds;
    }
  }

  Future<void> _loadData() async {
    final activeWs = ref.read(activeWorkspaceProvider);

    if (activeWs == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final contextTopic = (widget.activeNodeTitle != null && widget.activeNodeTitle!.isNotEmpty)
        ? widget.activeNodeTitle!
        : (activeWs.activeLearningContext.isNotEmpty 
            ? activeWs.activeLearningContext 
            : (activeWs.subject.isNotEmpty ? activeWs.subject : activeWs.title));

    // 1. Flashcards: use cached if available, else generate
    List<FlashcardItem> workspaceCards = activeWs.flashcards;
    List<FlashcardItem> topicCards = workspaceCards.where((c) => c.topicTag == contextTopic).toList();
    
    if (topicCards.isEmpty) {
      try {
        final flashRepo = ref.read(httpFlashcardRepositoryProvider);
        final newCards = await flashRepo.generateFlashcards(contextTopic);
        workspaceCards.addAll(newCards);
        activeWs.flashcards = workspaceCards;
        await ref.read(workspaceListProvider.notifier).updateWorkspace(activeWs);
        topicCards = newCards;
      } catch (e) {
        debugPrint('Flashcard generation failed: $e');
        topicCards = [];
      }
    }

    final activeNode = _findNodeByTitle(activeWs.roadmap, contextTopic);
    final String subtopicsContext = activeNode != null 
        ? activeNode.children.map((c) => c.title).join(", ") 
        : "";

    List<Map<String, dynamic>> videos = [];
    try {
      final repo = ref.read(httpWorkspaceRepositoryProvider);
      final enhancedContext = activeWs.subject.isNotEmpty && activeWs.subject != contextTopic
          ? "${activeWs.subject} $contextTopic $subtopicsContext tutorial".trim()
          : "$contextTopic $subtopicsContext tutorial".trim();
      videos = await repo.searchVideos(activeWs.id, contextTopic, context: enhancedContext);
      if (videos.isNotEmpty) {
        final videoId = videos.first['id'] as String?;
        if (videoId != null && videoId.isNotEmpty) {
          try {
            await ref.read(httpIngestionRepositoryProvider).ingestVideo(videoId);
          } catch (e) {
            debugPrint('Ingestion failed: $e');
          }
        }
      }
      debugPrint('Loaded videos count: ${videos.length} for context: $contextTopic');
    } catch (e) {
      debugPrint('Video search failed: $e');
    }

    final activityType = activeNode?.activityType ?? '';
    final isLongQuiz = activityType == 'Long Quiz' || activityType == 'LONG_QUIZ' || activityType == 'Mastery Assessment' || activityType == 'Mastery Survey';
    
    List<QuestionItem>? assessments;
    if (isLongQuiz) {
      try {
        final mRepo = ref.read(httpMasteryTestRepositoryProvider);
        assessments = await mRepo.generateAssessment(activeWs.activeLearningContext);
      } catch (e) {
        debugPrint('Mastery generation failed: $e');
      }
    }

    if (mounted) {
      setState(() {
        _topicFlashcards = topicCards;
        _topicVideos = videos;
        if (assessments != null) _topicAssessments = assessments;
        _isLoading = false;
      });
    }
  }

  void _handleAttachVideoToChat() {}

  void _handleAttachCardToChat(FlashcardItem card) {}

  void _handleAttachDiagramToChat(CanvasGridCell cell) {}

  void _handleReviewCard(String cardId, int quality) {
    setState(() {});
  }

  RoadmapNode? _findNodeByTitle(List<RoadmapNode>? nodes, String title) {
    if (nodes == null) return null;
    for (final n in nodes) {
      if (n.title == title) return n;
      final found = _findNodeByTitle(n.children, title);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    ref.listen(activeWorkspaceProvider, (previous, next) {
      final contextChanged = previous?.activeLearningContext != next?.activeLearningContext;
      final confirmationChanged = (previous?.isCourseConfirmed != true) && (next?.isCourseConfirmed == true);
      
      if (next != null && (contextChanged || confirmationChanged)) {
        setState(() {
          _isLoading = true;
        });
        _loadData();
      }
      if (next != null && (previous == null || previous.id != next.id)) {
        setState(() {
          _topicFlashcards = next.flashcards;
          _currentTimestampSeconds = next.videoTimestampSeconds;
        });
      }
    });

    final activeWs = ref.watch(activeWorkspaceProvider);
    final currentContext = widget.activeNodeTitle ?? activeWs?.activeLearningContext ?? 'Heap Memory';
    final videoTitle = _topicVideos.isNotEmpty 
        ? _topicVideos.first['title'] as String 
        : (activeWs != null ? '${activeWs.title}: $currentContext Walkthrough' : 'Module Walkthrough');
    final videoId = _topicVideos.isNotEmpty 
        ? _topicVideos.first['id'] as String 
        : '';
    final topicTag = currentContext;
    final currentCards = (activeWs?.flashcards ?? _topicFlashcards).where((c) => c.topicTag == topicTag).toList();
    final currentCells = activeWs?.canvasCells ?? widget.sharedCanvasCells;
    final currentObjects = activeWs?.canvasObjects ?? widget.sharedCanvasObjects;

    final stageContent = _isLoading
        ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
        : LayoutBuilder(
            builder: (context, leftConstraints) {
              if (_isScrollMode) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (widget.isEmbedded) _buildModeToggle(context),
                        SizedBox(
                          height: 400,
                          child: VideoPlayerPanel(
                            videoTitle: videoTitle,
                            videoId: videoId,
                            currentTimestampSeconds: _currentTimestampSeconds,
                            onTimestampChanged: (sec) {
                              setState(() => _currentTimestampSeconds = sec);
                              if (activeWs != null) {
                                activeWs.videoTimestampSeconds = sec;
                              }
                            },
                            onAttachVideoToChat: _handleAttachVideoToChat,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 550,
                          child: _showFlashcards
                              ? FlashcardDeckPanel(
                                  cards: currentCards,
                                  topicTag: topicTag,
                                  isScrollMode: true,
                                  onAttachCardToChat: _handleAttachCardToChat,
                                  onReviewCard: _handleReviewCard,
                                  onToggleToCanvas: () {
                                    setState(() => _showFlashcards = false);
                                  },
                                )
                              : BoundedGridCanvasWidget(
                                  gridCells: currentCells,
                                  customObjects: currentObjects,
                                  drawingPaths: widget.sharedDrawingPaths,
                                  onAttachDiagramToChat: _handleAttachDiagramToChat,
                                  onToggleToTranscript: () {
                                    setState(() => _showFlashcards = true);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    if (widget.isEmbedded) _buildModeToggle(context),
                    // Video Player
                    Expanded(
                      flex: (_videoFraction * 1000).toInt(),
                      child: VideoPlayerPanel(
                        videoTitle: videoTitle,
                        videoId: videoId,
                        currentTimestampSeconds: _currentTimestampSeconds,
                        onTimestampChanged: (sec) {
                          setState(() => _currentTimestampSeconds = sec);
                          if (activeWs != null) {
                            activeWs.videoTimestampSeconds = sec;
                          }
                        },
                        onAttachVideoToChat: _handleAttachVideoToChat,
                      ),
                    ),

                    // Vertical Split Resizer
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _videoFraction += details.delta.dy / leftConstraints.maxHeight;
                          _videoFraction = _videoFraction.clamp(0.20, 0.80);
                        });
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeRow,
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: colors.bgActivityBar,
                          child: Center(
                            child: Divider(
                              color: colors.borderSubtle,
                              thickness: 1,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Flashcards Panel or Canvas Panel
                    Expanded(
                      flex: ((1.0 - _videoFraction) * 1000).toInt(),
                      child: _showFlashcards
                          ? FlashcardDeckPanel(
                              cards: currentCards,
                              topicTag: topicTag,
                              isScrollMode: false,
                              onAttachCardToChat: _handleAttachCardToChat,
                              onReviewCard: _handleReviewCard,
                              onToggleToCanvas: () {
                                setState(() => _showFlashcards = false);
                              },
                            )
                          : BoundedGridCanvasWidget(
                              gridCells: currentCells,
                              customObjects: currentObjects,
                              drawingPaths: widget.sharedDrawingPaths,
                              onAttachDiagramToChat: _handleAttachDiagramToChat,
                              onToggleToTranscript: () {
                                setState(() => _showFlashcards = true);
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );

    final activeNode = _findNodeByTitle(activeWs?.roadmap, currentContext);
    final activityType = activeNode?.activityType ?? '';
    final isMicroQuiz = activityType == 'Micro Quiz' || activityType == 'MICRO_QUIZ';
    final isLongQuiz = activityType == 'Long Quiz' || activityType == 'LONG_QUIZ' || activityType == 'Mastery Assessment' || activityType == 'Mastery Survey';
    final isCodeChallenge = activityType == 'Coding Exercise' || activityType == 'CODE_CHALLENGE' || activityType == 'Mini Project' || activityType == 'Capstone Project' || activityType == 'Interview Challenge';

    Widget activityStageContent;
    if (_isLoading) {
      activityStageContent = Center(child: CircularProgressIndicator(color: colors.accentPrimary));
    } else if (isLongQuiz && _dismissedQuizForContext != currentContext) {
      activityStageContent = _topicAssessments == null 
        ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
        : LongMcqSurveyLayout(
        questions: _topicAssessments!,
        onCompleteTest: () {
          setState(() {
            _dismissedQuizForContext = currentContext;
            if (activeNode != null) activeNode.status = 'Completed';
          });
          if (widget.onUndoBackToMindMap != null) {
            widget.onUndoBackToMindMap!();
          }
        },
      );
    } else if (isCodeChallenge && _dismissedQuizForContext != currentContext) {
      activityStageContent = CodeTerminalChallengeLayout(
        question: QuestionItem(id: 'c1', topicTag: 'code', questionText: 'Write a Python program', type: QuestionType.subjective, options: []),
        onCompleteTest: () {
          setState(() {
            _dismissedQuizForContext = currentContext;
            if (activeNode != null) activeNode.status = 'Completed';
          });
        },
      );
    } else {
      if (isMicroQuiz && _dismissedQuizForContext != currentContext) {
        activityStageContent = Stack(
          children: [
            stageContent,
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: PopupQuestionnaireLayout(
                      questions: const [],
                      onCompleteTest: () {
                        setState(() {
                          _dismissedQuizForContext = currentContext;
                          if (activeNode != null) activeNode.status = 'Completed';
                        });
                      },
                      onClose: () {
                        setState(() {
                          _dismissedQuizForContext = currentContext;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        activityStageContent = stageContent;
      }
    }

    if (widget.isEmbedded) {
      return Container(
        color: colors.bgCanvas,
        child: activityStageContent,
      );
    }

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Column(
        children: [
          _buildWorkspaceHeader(context, currentContext),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxChatWidth = constraints.maxWidth - 340.0;

                return Row(
                  children: [
                    Expanded(child: activityStageContent),
                    // Horizontal Draggable Splitter (Left Stage ↔ AI Chat)
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _chatPanelWidth -= details.delta.dx;
                          _chatPanelWidth = _chatPanelWidth.clamp(260.0, maxChatWidth);
                        });
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: Container(
                          width: 6,
                          color: colors.bgActivityBar,
                          child: Center(
                            child: VerticalDivider(color: colors.borderSubtle, thickness: 1, width: 2),
                          ),
                        ),
                      ),
                    ),
                    // Right Pane: Resizable AI Chatbot / Roadmap Sidebar
                    SizedBox(
                      width: _chatPanelWidth,
                      child: LearningLabSidebar(
                        onInterviewComplete: widget.onUndoBackToMindMap ?? () {},
                        onSelectNode: (nodeTitle) {
                          final activeWs = ref.read(activeWorkspaceProvider);
                          if (activeWs != null) {
                            ref.read(workspaceListProvider.notifier).updateActiveLearningContext(activeWs.id, nodeTitle);
                          }
                        },
                        onAcceptCard: _handleAttachCardToChat,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {
              setState(() => _isScrollMode = !_isScrollMode);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isScrollMode ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isScrollMode ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(
                    _isScrollMode ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                    size: 13,
                    color: _isScrollMode ? colors.accentPrimary : colors.fgSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isScrollMode ? 'Split Mode' : 'Scroll Mode',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _isScrollMode ? colors.accentPrimary : colors.fgSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceHeader(BuildContext context, String currentContext) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgActivityBar,
        border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          if (widget.onUndoBackToMindMap != null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.borderActive),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: Icon(Icons.undo_rounded, size: 16, color: colors.accentPrimary),
              label: Text('Back to Mind Map', style: TextStyle(fontSize: 12, color: colors.accentPrimary, fontWeight: FontWeight.bold)),
              onPressed: widget.onUndoBackToMindMap,
            ),
          if (widget.onUndoBackToMindMap != null) const SizedBox(width: 16),
          Text(
            'Learning Lab Workspace',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.fgPrimary,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.accentEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Active: $currentContext', style: TextStyle(fontSize: 11, color: colors.accentEmerald, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),

          // Layout Mode Toggle Button (Scroll Mode vs Split Mode)
          InkWell(
            onTap: () {
              setState(() {
                _isScrollMode = !_isScrollMode;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isScrollMode ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgCanvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isScrollMode ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(
                    _isScrollMode ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                    size: 14,
                    color: _isScrollMode ? colors.accentPrimary : colors.fgSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isScrollMode ? 'Split Mode' : 'Scroll Mode',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _isScrollMode ? colors.accentPrimary : colors.fgSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
