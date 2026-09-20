import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/stomp_chat_service.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/models/roadmap_model.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../../shared/models/mastery_test_model.dart';
import '../../../shared/models/learning_lab_model.dart';
import '../../../shared/providers/workspace_providers.dart';
import '../../survey/data/http_assessment_repository.dart';
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
import '../../../shared/repositories/http_challenge_repository.dart';
import '../../exam/presentation/proctored_exam_screen.dart';
import '../../exam/presentation/widgets/exam_configuration_dialog.dart';

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
  QuestionItem? _topicChallenge;

  List<FlashcardItem> _topicFlashcards = [];
  List<Map<String, dynamic>> _topicVideos = [];
  bool _isLoading = true;
  bool _isLoadingInProgress = false;
  String? _dismissedQuizForContext;

  int _currentTimestampSeconds = 342;
  bool _showFlashcards = true; // true = flashcards deck, false = drawing canvas
  bool _isScrollMode = false; // false = split view (resizable), true = full scroll view
  double _chatPanelWidth = 360.0;
  double _videoFraction = 0.70; // Video takes 70%, flashcards/canvas takes 30% in split mode
  StreamSubscription<Map<String, dynamic>>? _ingestionSubscription;
  String? _ingestionStatus;

  @override
  void dispose() {
    _ingestionSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    final activeWs = ref.read(activeWorkspaceProvider);
    if (activeWs != null) {
      _currentTimestampSeconds = activeWs.videoTimestampSeconds;
    }
  }

  @override
  void didUpdateWidget(covariant LearningLabWorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeNodeTitle != oldWidget.activeNodeTitle && widget.activeNodeTitle != null) {
      setState(() {
        _isLoading = true;
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_isLoadingInProgress) return;
    _isLoadingInProgress = true;
    final activeWs = ref.read(activeWorkspaceProvider);

    if (activeWs == null) {
      _isLoadingInProgress = false;
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

    final activeNode = _findNodeByTitle(activeWs.roadmap, contextTopic);
    final activityType = activeNode?.activityType ?? '';
    final isMicroQuiz = activityType == 'Micro Quiz' || activityType == 'MICRO_QUIZ';
    final isLongQuiz = activityType == 'Long Quiz' || activityType == 'LONG_QUIZ' || activityType == 'Mastery Assessment' || activityType == 'Mastery Survey';
    final isQuiz = isMicroQuiz || isLongQuiz;
    final isCodeChallenge = activityType == 'Coding Exercise' || activityType == 'CODE_CHALLENGE' || activityType == 'Mini Project' || activityType == 'Capstone Project' || activityType == 'Interview Challenge';

    // 1. Parallel Task A: Flashcards fetch / generation
    Future<List<FlashcardItem>> fetchFlashcards() async {
      final workspaceCards = activeWs.flashcards;
      final target = contextTopic.toLowerCase().replaceAll(RegExp(r'^module\s*\d+:\s*'), '').trim();
      List<FlashcardItem> topicCards = workspaceCards.where((c) {
        final tag = c.topicTag.toLowerCase().replaceAll(RegExp(r'^module\s*\d+:\s*'), '').trim();
        return tag == target || (tag.isNotEmpty && target.contains(tag)) || (target.isNotEmpty && tag.contains(target));
      }).toList();

      if (topicCards.isEmpty) {
        try {
          final flashRepo = ref.read(httpFlashcardRepositoryProvider);
          final newCards = await flashRepo.generateFlashcards(contextTopic);
          workspaceCards.addAll(newCards);
          activeWs.flashcards = workspaceCards;
          ref.read(workspaceListProvider.notifier).updateWorkspace(activeWs);
          return newCards;
        } catch (e) {
          debugPrint('Flashcard generation failed: $e');
          return workspaceCards;
        }
      }
      return topicCards;
    }

    // 2. Parallel Task B: YouTube Video Search
    Future<List<Map<String, dynamic>>> fetchVideos() async {
      try {
        final repo = ref.read(httpWorkspaceRepositoryProvider);
        final cleanSubject = activeWs.subject.toLowerCase().replaceAll(RegExp(r'^module\s*\d+:\s*'), '').trim();
        final cleanTopic = contextTopic.toLowerCase().replaceAll(RegExp(r'^module\s*\d+:\s*'), '').trim();
        final enhancedContext = cleanSubject.isNotEmpty && cleanSubject != cleanTopic
            ? "${activeWs.subject} tutorial"
            : "tutorial";
        return await repo.searchVideos(activeWs.id, contextTopic, context: enhancedContext);
      } catch (e) {
        debugPrint('Video search failed: $e');
        return [];
      }
    }

    // 3. Parallel Task C: Assessment (if quiz)
    Future<List<QuestionItem>?> fetchAssessment() async {
      if (!isQuiz) return null;
      try {
        final mRepo = ref.read(httpAssessmentRepositoryProvider);
        return await mRepo.generateAssessment(activeWs.activeLearningContext);
      } catch (e) {
        debugPrint('Mastery generation failed: $e');
        return null;
      }
    }

    // Execute independent tasks concurrently via Future.wait
    final results = await Future.wait([
      fetchFlashcards(),
      fetchVideos(),
      fetchAssessment(),
    ]);

    final topicCards = results[0] as List<FlashcardItem>;
    final videos = results[1] as List<Map<String, dynamic>>;
    final assessments = results[2] as List<QuestionItem>?;

    // Asynchronously kick off video ingestion in background without blocking UI
    if (videos.isNotEmpty) {
      final videoId = videos.first['id'] as String?;
      if (videoId != null && videoId.isNotEmpty) {
        try {
          _ingestionSubscription?.cancel();
          _ingestionSubscription = ref.read(stompChatServiceProvider).streamIngestionProgress(videoId).listen((event) {
            if (mounted) {
              setState(() {
                final step = event['step'] as String? ?? '';
                final status = event['status'] as String? ?? '';
                if (step == 'COMPLETE' || step == 'ERROR') {
                  _ingestionStatus = null;
                } else {
                  _ingestionStatus = 'AI Analysis: $status';
                }
              });
            }
          });
          ref.read(httpIngestionRepositoryProvider).ingestVideo(videoId).catchError((e) {
            debugPrint('Background video ingestion error: $e');
          });
        } catch (e) {
          debugPrint('Ingestion stream listener error: $e');
        }
      }
    }

    // 4. Code Challenge generation (passes videoId from video result if available)
    QuestionItem? challengeItem;
    if (isCodeChallenge) {
      try {
        final challengeRepo = ref.read(httpChallengeRepositoryProvider);
        final targetLang = activeWs.subject.isNotEmpty ? activeWs.subject : 'Python';
        final videoId = videos.isNotEmpty ? (videos.first['id'] as String? ?? '') : '';
        final challengeData = await challengeRepo.generateChallenge(
          language: targetLang,
          topic: contextTopic,
          videoId: videoId,
          videoTimestamp: _currentTimestampSeconds,
        );
        final rawCases = (challengeData['testCases'] as List<dynamic>?) ?? [];
        challengeItem = QuestionItem(
          id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
          questionText: challengeData['problemStatement']?.toString() ?? 'Solve the challenge for $contextTopic.',
          topicTag: contextTopic,
          type: QuestionType.codeTerminal,
          codeInitialTemplate: challengeData['starterCode']?.toString(),
          language: targetLang,
          testCases: rawCases.map((tc) => CodeTestCase(
            id: 'tc_${rawCases.indexOf(tc)}',
            description: tc.toString(),
            expectedOutput: '',
            userOutput: '',
            isPassed: false,
          )).toList(),
        );
      } catch (e) {
        debugPrint('Dynamic challenge generation failed: $e');
      }
    }

    _isLoadingInProgress = false;
    if (mounted) {
      setState(() {
        _topicFlashcards = topicCards;
        _topicVideos = videos;
        if (assessments != null) _topicAssessments = assessments;
        if (challengeItem != null) _topicChallenge = challengeItem;
        _isLoading = false;
      });
    }
  }

  void _handleAttachVideoToChat() {
    final videoTitle = _topicVideos.isNotEmpty ? (_topicVideos.first['title'] as String? ?? 'Current Video') : 'Current Video';
    final timestamp = _currentTimestampSeconds > 0
        ? ' [at ${_currentTimestampSeconds ~/ 60}:${(_currentTimestampSeconds % 60).toString().padLeft(2, '0')}]'
        : '';
    final prompt = 'Can you explain the key concepts demonstrated in "$videoTitle"$timestamp?';

    ref.read(sidebarSelectedTabProvider.notifier).state = 0;
    ref.read(chatPrefillInputProvider.notifier).state = prompt;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attached video context to chat: $videoTitle'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleAttachCardToChat(FlashcardItem card) {
    final prompt = 'Can you explain this flashcard: "${card.front}"? (Expected answer: "${card.back}")';

    ref.read(sidebarSelectedTabProvider.notifier).state = 0;
    ref.read(chatPrefillInputProvider.notifier).state = prompt;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attached flashcard to chat: "${card.front}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleAttachDiagramToChat(CanvasGridCell cell) {
    final prompt = 'Can you explain the architecture diagram block: "${cell.title}" (${cell.diagramType})?';

    ref.read(sidebarSelectedTabProvider.notifier).state = 0;
    ref.read(chatPrefillInputProvider.notifier).state = prompt;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attached diagram node to chat: ${cell.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleReviewCard(String cardId, int quality) {
    ref.read(httpFlashcardRepositoryProvider).reviewFlashcard(cardId, quality);
  }

  RoadmapNode? _findNodeByTitle(List<RoadmapNode>? nodes, String title) {
    if (nodes == null || title.isEmpty) return null;
    final cleanTitle = title.toLowerCase().replaceAll(RegExp(r'^module\s*\d+:\s*'), '').trim();
    for (final n in nodes) {
      final nodeTitle = n.title.toLowerCase().replaceAll(RegExp(r'^module\s*\d+:\s*'), '').trim();
      if (n.title.toLowerCase() == title.toLowerCase() || 
          nodeTitle == cleanTitle || 
          (cleanTitle.isNotEmpty && nodeTitle.contains(cleanTitle)) || 
          (nodeTitle.isNotEmpty && cleanTitle.contains(nodeTitle))) {
        return n;
      }
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
      final workspaceChanged = previous != null && next != null && previous.id != next.id;
      final confirmationChanged = (previous?.isCourseConfirmed != true) && (next?.isCourseConfirmed == true);
      
      if (next != null && (contextChanged || workspaceChanged || confirmationChanged)) {
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
    final currentContext = widget.activeNodeTitle ?? activeWs?.activeLearningContext ?? activeWs?.subject ?? 'Getting Started';
    final videoTitle = _topicVideos.isNotEmpty 
        ? _topicVideos.first['title'] as String 
        : (activeWs != null ? '${activeWs.title}: $currentContext Walkthrough' : 'Module Walkthrough');
    final videoId = _topicVideos.isNotEmpty 
        ? _topicVideos.first['id'] as String 
        : '';
    final topicTag = currentContext;
    final allCards = (activeWs?.flashcards != null && activeWs!.flashcards.isNotEmpty) 
        ? activeWs.flashcards 
        : _topicFlashcards;
    final cleanTopicTag = topicTag.toLowerCase().replaceAll(RegExp(r'^module\s*\d+:\s*'), '').trim();
    final currentCards = allCards.where((c) {
      final tag = c.topicTag.toLowerCase().replaceAll(RegExp(r'^module\s*\d+:\s*'), '').trim();
      return tag == cleanTopicTag || (tag.isNotEmpty && cleanTopicTag.contains(tag)) || (cleanTopicTag.isNotEmpty && tag.contains(cleanTopicTag));
    }).toList();
    final displayedCards = currentCards.isNotEmpty ? currentCards : allCards;
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
                                  cards: displayedCards,
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
                    if (_ingestionStatus != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.accentPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _ingestionStatus!,
                              style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
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
                              cards: displayedCards,
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
      activityStageContent = (_topicAssessments == null || _topicAssessments!.isEmpty)
        ? stageContent
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
      activityStageContent = _topicChallenge == null
        ? stageContent
        : CodeTerminalChallengeLayout(
            question: _topicChallenge!,
            onCompleteTest: () {
              setState(() {
                _dismissedQuizForContext = currentContext;
                if (activeNode != null) activeNode.status = 'Completed';
              });
            },
          );
    } else {
      if (isMicroQuiz && _dismissedQuizForContext != currentContext && _topicAssessments != null && _topicAssessments!.isNotEmpty) {
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
                      questions: _topicAssessments!,
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
          // Launch Proctored Exam Capstone Button
          InkWell(
            onTap: () {
              ExamConfigurationDialog.show(
                context,
                courseTitle: currentContext,
                onStartExam: (dur, scheme) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ProctoredExamScreen(
                        durationMinutes: dur,
                        markingScheme: scheme,
                        onExit: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  );
                },
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.accentCyan.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: colors.accentCyan),
                  const SizedBox(width: 6),
                  Text(
                    'Take Proctored Exam',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.accentCyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

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
