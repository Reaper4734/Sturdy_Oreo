import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/models/micro_interview_model.dart';
import '../../../shared/models/workspace_model.dart';
import '../../../shared/providers/workspace_providers.dart';
import '../../../shared/repositories/http_interview_repository.dart';
import '../../../shared/services/file_picker_service.dart';
import '../../../shared/services/voice_assistant_service.dart';
import 'dart:convert';
import '../../workspace/data/http_workspace_repository.dart';
import 'widgets/workspace_generation_interstitial.dart';
import '../../../shared/services/stomp_chat_service.dart';

class MicroInterviewScreen extends ConsumerStatefulWidget {
  final VoidCallback onInterviewComplete;
  final bool showHeader;
  final bool isWorkspaceMode;

  const MicroInterviewScreen({
    super.key,
    required this.onInterviewComplete,
    this.showHeader = true,
    this.isWorkspaceMode = false,
  });

  @override
  ConsumerState<MicroInterviewScreen> createState() => _MicroInterviewScreenState();
}

class _MicroInterviewScreenState extends ConsumerState<MicroInterviewScreen> {
  final FilePickerService _filePickerService = FilePickerService();
  final VoiceAssistantService _voiceService = VoiceAssistantService();

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  final List<AttachedFileModel> _attachedFiles = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showVoiceModal = false;
  bool _isGeneratingWorkspace = false;
  bool _lastMessageFinishedAnim = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onTextChanged);
    _setupKeyboardShortcuts();
    _loadInitialMessages();
  }

  void _setupKeyboardShortcuts() {
    _inputFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter;
        if (isEnter) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            // Shift + Enter -> Allow multiline newline insertion & move cursor down
            return KeyEventResult.ignored;
          } else {
            // Enter alone -> Send message
            final text = _inputController.text;
            if (text.trim().isNotEmpty || _attachedFiles.isNotEmpty) {
              _handleUserMessage(text);
            }
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to toggle Send vs Mic/Voice button dynamically
  }

  @override
  void dispose() {
    _inputController.removeListener(_onTextChanged);
    _inputFocusNode.dispose();
    _voiceService.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    final activeWs = ref.read(activeWorkspaceProvider);

    if (widget.isWorkspaceMode) {
      if (activeWs != null && activeWs.chatHistory.isNotEmpty) {
        if (mounted) {
          setState(() {
            _messages = List.from(activeWs.chatHistory);
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _messages = [
            ChatMessage(
              id: 'ws_welcome',
              sender: 'AI',
              text: "Hello! I'm Oreo AI, your learning assistant for **${activeWs?.title ?? 'this workspace'}**. Ask me questions about your modules, concepts, or request curriculum changes!",
            )
          ];
          _isLoading = false;
        });
      }
      return;
    }

    // Onboarding Interview Mode
    try {
      final repo = ref.read(httpInterviewRepositoryProvider);
      final initialMsg = await repo.sendInterviewMessage("Start the interview", "");
      if (mounted) {
        setState(() {
          _messages = [initialMsg];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages = [ChatMessage(id: 'err', sender: 'AI', text: "Failed to connect to backend: $e")];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    final picked = await _filePickerService.pickFiles();
    if (picked.isNotEmpty) {
      setState(() {
        _attachedFiles.addAll(picked);
      });
    }
  }

  void _removeFile(String fileId) {
    setState(() {
      _attachedFiles.removeWhere((f) => f.id == fileId);
    });
  }

  Future<void> _handleUserMessage(String text) async {
    if ((text.trim().isEmpty && _attachedFiles.isEmpty) || _isSending) return;

    final userMsg = ChatMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'USER',
      text: text,
      attachments: List.from(_attachedFiles),
    );

    final sentFiles = List<AttachedFileModel>.from(_attachedFiles);

    setState(() {
      _messages.add(userMsg);
      _attachedFiles.clear();
      _isSending = true;
    });

    final activeWs = ref.read(activeWorkspaceProvider);
    if (widget.isWorkspaceMode && activeWs != null) {
      activeWs.chatHistory = List.from(_messages);
      ref.read(workspaceListProvider.notifier).updateWorkspace(activeWs);

      // Conversational Workspace Editing
      if (text.toLowerCase().contains('already know') || text.toLowerCase().contains('master')) {
        activeWs.progressPercent = (activeWs.progressPercent + 0.15).clamp(0.0, 1.0);
        triggerAutoSaveFeedback(ref);
      }
    }

    _inputController.clear();
    _scrollToBottom();

    final repo = ref.read(httpInterviewRepositoryProvider);
    // Sanitize conversation history to prevent prompt leakage and fallback leakage into LLM context
    final historyStr = _messages
        .where((m) => !m.text.startsWith('The AI Tutor is currently experiencing high traffic') && 
                      !m.text.startsWith('Error:') &&
                      !m.text.startsWith('Unauthorized:'))
        .map((m) {
          final cleanText = m.text.replaceAll(RegExp(r'```(?:canvas-diagram|json)?[\s\S]*?```', caseSensitive: false), '').trim();
          return "${m.sender}: ${cleanText.isNotEmpty ? cleanText : m.text}";
        })
        .join("\n");

    final stompService = ref.read(stompChatServiceProvider);

    try {
      if (widget.isWorkspaceMode && sentFiles.isEmpty) {
        final sessionId = activeWs?.id ?? 'ws_${DateTime.now().millisecondsSinceEpoch}';
        final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
        var accumulated = '';
        var placeholderAdded = false;

        try {
          final stream = stompService.streamCanvasExplanation(
            userMessage: text,
            sessionId: sessionId,
            timestamp: activeWs != null ? '${activeWs.videoTimestampSeconds}' : null,
            userId: activeWs?.userId ?? 'user_active',
          );

          await for (final token in stream) {
            accumulated += token;
            if (mounted) {
              setState(() {
                if (!placeholderAdded) {
                  _messages.add(ChatMessage(
                    id: aiMsgId,
                    sender: 'AI',
                    text: accumulated,
                  ));
                  placeholderAdded = true;
                } else {
                  _messages[_messages.length - 1] = ChatMessage(
                    id: aiMsgId,
                    sender: 'AI',
                    text: accumulated,
                  );
                }
              });
              _scrollToBottom();
            }
          }
        } catch (streamErr) {
          debugPrint('STOMP stream encountered issue, falling back to HTTP: $streamErr');
          if (!placeholderAdded) {
            String roadmapJson = "[]";
            if (activeWs != null) {
              roadmapJson = jsonEncode(activeWs.roadmap.map((e) => e.toJson()).toList());
            }
            final aiReply = await repo.sendWorkspaceChatMessage(
              text,
              historyStr,
              roadmapJson,
              files: sentFiles,
            );
            if (mounted) {
              setState(() {
                _messages.add(aiReply);
              });
            }
          }
        }

        if (mounted) {
          setState(() {
            _lastMessageFinishedAnim = false;
            _isSending = false;
          });
          if (activeWs != null) {
            activeWs.chatHistory = List.from(_messages);
            ref.read(workspaceListProvider.notifier).updateWorkspace(activeWs);
          }
          _scrollToBottom();
        }
        return;
      }

      ChatMessage aiReply;
      if (widget.isWorkspaceMode) {
        String roadmapJson = "[]";
        if (activeWs != null) {
          roadmapJson = jsonEncode(activeWs.roadmap.map((e) => e.toJson()).toList());
        }
        aiReply = await repo.sendWorkspaceChatMessage(
          text,
          historyStr,
          roadmapJson,
          files: sentFiles,
        );
      } else {
        aiReply = await repo.sendInterviewMessage(
          text,
          historyStr,
          files: sentFiles,
        );
      }

      if (mounted) {
        setState(() {
          _lastMessageFinishedAnim = false;
          _messages.add(aiReply);
          _isSending = false;
        });
        if (widget.isWorkspaceMode && activeWs != null) {
          activeWs.chatHistory = List.from(_messages);
          ref.read(workspaceListProvider.notifier).updateWorkspace(activeWs);
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            id: 'err_${DateTime.now().millisecondsSinceEpoch}',
            sender: 'AI',
            text: "Sorry, I ran into an issue processing that: $e",
          ));
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleVoiceAssistantModal() {
    setState(() {
      _showVoiceModal = !_showVoiceModal;
    });

    if (_showVoiceModal) {
      _voiceService.startListening(
        onRecognizedText: (recognizedText) {
          _inputController.text = recognizedText;
          _handleUserMessage(recognizedText);
          if (mounted) {
            setState(() {
              _showVoiceModal = false;
            });
          }
        },
      );
    } else {
      _voiceService.stopListening();
    }
  }

  bool get _canSend => _inputController.text.trim().isNotEmpty || _attachedFiles.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    ref.listen(activeWorkspaceProvider, (previous, next) {
      if (widget.isWorkspaceMode && next != null && (previous == null || previous.id != next.id)) {
        setState(() {
          _messages = List.from(next.chatHistory);
        });
      }
    });

    ref.listen<String?>(chatPrefillInputProvider, (previous, next) {
      if (next != null && next.isNotEmpty && mounted) {
        _inputController.text = next;
        _inputFocusNode.requestFocus();
        Future.microtask(() => ref.read(chatPrefillInputProvider.notifier).state = null);
      }
    });

    if (_isGeneratingWorkspace) {
      return WorkspaceGenerationInterstitial(
        topicName: 'Personalized Learning Curriculum',
        onCompleted: () async {
          final messenger = ScaffoldMessenger.of(context);
          WorkspaceModel newWs;
          try {
             final repo = ref.read(httpWorkspaceRepositoryProvider);
             final lastAiMsg = _messages.reversed.firstWhere((m) => m.sender == 'AI', orElse: () => _messages.last);
             final metadata = lastAiMsg.metadata ?? {};
             final persona = metadata['current_inferred_persona'] as Map<String, dynamic>? ?? {};
             
             // Extract subject with intelligent fallback from conversation text if persona subject is missing
             String subject = (persona['subject'] as String?)?.trim() ?? '';
             if (subject.isEmpty || subject.toLowerCase() == 'general knowledge') {
                for (final m in _messages.reversed) {
                  final text = m.text;
                  final match = RegExp(r'personalized\s+([A-Za-z0-9\s\+#]+?)\s+learning', caseSensitive: false).firstMatch(text);
                  if (match != null && (match.group(1)?.trim().isNotEmpty ?? false)) {
                     subject = match.group(1)!.trim();
                     break;
                  }
                }
                if (subject.isEmpty) {
                   subject = persona['subject'] ?? 'Personalized Course';
                }
             }
             final domain = persona['domain'] ?? 'Technology';
             final personaStr = "Domain: $domain, Subject: $subject, Score: ${metadata['confidence_score'] ?? 90}";
             
             newWs = await repo.createWorkspaceFromCourse(subject, persona: personaStr);
             // Preserve the complete onboarding chat history inside the newly created workspace
             newWs.chatHistory = List.from(_messages);
          } catch (e) {
             debugPrint('Workspace generation failed: $e');
             // Rethrow — don't silently create mock data
             if (mounted) {
               setState(() { _isGeneratingWorkspace = false; });
               messenger.showSnackBar(
                 SnackBar(content: Text('Failed to generate curriculum: $e'), backgroundColor: Colors.red),
               );
             }
             return;
          }
          
          await ref.read(workspaceListProvider.notifier).createWorkspace(newWs);
          ref.read(activeWorkspaceIdProvider.notifier).state = newWs.id;

          if (mounted) {
            setState(() {
              _isGeneratingWorkspace = false;
            });
            widget.onInterviewComplete();
          }
        },
      );
    }

    final colors = context.colors;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colors.bgCanvas,
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
              : Column(
                  children: [
                    // Top Header Bar
                    if (widget.showHeader) _buildHeader(context),

                    // Main Viewport (ChatGPT Landing when empty vs Active Unboxed Chat Thread)
                    Expanded(
                      child: Stack(
                        children: [
                          if (_messages.isEmpty)
                            _buildChatGPTLandingState(context)
                          else
                            _buildActiveChatThread(context),
                        ],
                      ),
                    ),

                    // Bottom Floating Input Bar + Disclaimer (Always visible when in active chat thread)
                    if (_messages.isNotEmpty) _buildBottomInputArea(context),
                  ],
                ),
        ),

        // Live Voice Assistant Modal Overlay
        if (_showVoiceModal) _buildVoiceAssistantModal(context),
      ],
    );
  }

  // Top Header Bar
  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgActivityBar,
        border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'Oreo AI Tutor',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, color: colors.fgSecondary, size: 18),
          const Spacer(),
        ],
      ),
    );
  }

  // ChatGPT Centered Landing View State (Single Centered Input Bar)
  Widget _buildChatGPTLandingState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'What do you want to learn today?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.w600, color: colors.fgPrimary),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 32),

              // Single Centered Floating Input Box on Landing
              _buildPillInputBox(context),
              const SizedBox(height: 24),

              // Quick Prompt Cards (Monochrome Minimalist)
              Column(
                children: [
                  _buildQuickActionItem(
                    icon: Icons.image_outlined,
                    label: 'Attach Notes / Syllabus (PDF, DOCX, MD)',
                    onTap: _pickFiles,
                  ),
                  _buildQuickActionItem(
                    icon: Icons.edit_note_outlined,
                    label: 'Master Python OOPs & Backend Architecture',
                    onTap: () => _handleUserMessage('Master Python OOPs & Backend Architecture'),
                  ),
                  _buildQuickActionItem(
                    icon: Icons.language_outlined,
                    label: 'Build Real-Time React WebSocket Dashboard',
                    onTap: () => _handleUserMessage('Build Real-Time React WebSocket Dashboard'),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ChatGPT Active Conversation View State (Unboxed AI Messages - Screenshot 2 Style)
  Widget _buildActiveChatThread(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final colors = context.colors;
            final msg = _messages[index];
            final isAI = msg.sender == 'AI';
            return Column(
              crossAxisAlignment: isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                // File Attachments if present
                if (msg.attachments != null && msg.attachments!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: isAI ? WrapAlignment.start : WrapAlignment.end,
                      children: msg.attachments!.map((f) => _buildAttachedFileChip(context, f, isDismissible: false)).toList(),
                    ),
                  ),

                // USER Message (Sleek Elevated Pill) vs AI Message (Unboxed Text directly on Canvas)
                if (!isAI)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    constraints: const BoxConstraints(maxWidth: 550),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.borderSubtle, width: 1),
                      boxShadow: AppElevation.low,
                    ),
                    child: Text(msg.text, style: TextStyle(color: colors.fgPrimary, fontSize: 15)),
                  ).animate().fadeIn(duration: 200.ms)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Unboxed AI Response Text with on-the-fly Markdown formatting & fast streaming
                        if (index == _messages.length - 1 && !_lastMessageFinishedAnim)
                          StreamingMarkdownBody(
                            text: msg.text,
                            styleSheet: MarkdownStyleSheet(
                              p: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.fgPrimary),
                              strong: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.fgPrimary),
                              listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.fgPrimary),
                            ),
                            onTick: _scrollToBottom,
                            onFinished: () {
                              if (mounted) {
                                setState(() {
                                  _lastMessageFinishedAnim = true;
                                });
                              }
                            },
                          )
                        else
                          MarkdownBody(
                            data: msg.text,
                            styleSheet: MarkdownStyleSheet(
                              p: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.fgPrimary),
                              strong: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.fgPrimary),
                              listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.fgPrimary),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Action Bar Below AI Message (Copy, Like, Dislike, Share, Retry)
                        Row(
                          children: [
                            _buildIconActionButton(context, Icons.content_copy_outlined, 'Copy', () {
                              Clipboard.setData(ClipboardData(text: msg.text));
                            }),
                            const SizedBox(width: 4),
                            _buildIconActionButton(context, Icons.thumb_up_outlined, 'Good response', () {}),
                            const SizedBox(width: 4),
                            _buildIconActionButton(context, Icons.thumb_down_outlined, 'Bad response', () {}),
                            const SizedBox(width: 4),
                            _buildIconActionButton(context, Icons.refresh_rounded, 'Regenerate', () {}),
                            const SizedBox(width: 4),
                            _buildIconActionButton(context, Icons.more_horiz_rounded, 'More', () {}),
                          ],
                        ),

                        // Interactive Option Chips & Generate Curriculum CTA
                        () {
                          final effectiveOptions = List<String>.from(msg.options ?? []);
                          if (!widget.isWorkspaceMode && isAI) {
                            final textLower = msg.text.toLowerCase();
                            final mentionsCurriculum = textLower.contains('generate') && 
                                (textLower.contains('curriculum') || textLower.contains('learning path') || textLower.contains('path') || textLower.contains('plan'));
                            final hasConfidence = (msg.metadata?['confidence_score'] is num && (msg.metadata!['confidence_score'] as num) >= 80);

                            if (mentionsCurriculum || hasConfidence) {
                              if (!effectiveOptions.any((o) => o.contains('➔') || o.toLowerCase().contains('generate curriculum'))) {
                                effectiveOptions.add('Generate Curriculum ➔');
                              }
                            }
                          }

                          if (effectiveOptions.isEmpty) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              children: effectiveOptions.map((opt) {
                                final isNavCTA = opt.contains('➔') || opt.toLowerCase().contains('generate curriculum');

                                if (widget.isWorkspaceMode) {
                                  final activeWs = ref.watch(activeWorkspaceProvider);
                                  final isConfirmed = activeWs?.isCourseConfirmed == true;
                                  final hasCurriculum = activeWs != null && activeWs.roadmap.isNotEmpty;

                                  // If confirmed in workspace mode, hide generate CTA
                                  if (isNavCTA && isConfirmed) {
                                    return const SizedBox.shrink();
                                  }

                                  final label = (isNavCTA && hasCurriculum)
                                      ? '✨ Ask to update/edit curriculum'
                                      : opt;

                                  return ActionChip(
                                    backgroundColor: isNavCTA ? colors.accentEmerald.withValues(alpha: 0.15) : colors.bgSurface,
                                    side: BorderSide(
                                      color: isNavCTA ? colors.accentEmerald : colors.borderSubtle,
                                    ),
                                    label: Text(
                                      label,
                                      style: TextStyle(
                                        color: isNavCTA ? colors.accentEmerald : colors.fgPrimary,
                                        fontWeight: isNavCTA ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (isNavCTA && !hasCurriculum) {
                                        setState(() {
                                          _isGeneratingWorkspace = true;
                                        });
                                      } else if (isNavCTA && hasCurriculum) {
                                        _handleUserMessage('Please help me update and refine the curriculum modules.');
                                      } else {
                                        _handleUserMessage(opt);
                                      }
                                    },
                                  );
                                }

                                // Onboarding Interview Mode: Always render prominent CTA if isNavCTA
                                if (isNavCTA) {
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isGeneratingWorkspace = true;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: colors.accentEmerald,
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colors.accentEmerald.withValues(alpha: 0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              opt,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return ActionChip(
                                  backgroundColor: colors.bgSurface,
                                  side: BorderSide(color: colors.borderSubtle),
                                  label: Text(
                                    opt,
                                    style: TextStyle(
                                      color: colors.fgPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onPressed: () => _handleUserMessage(opt),
                                );
                              }).toList(),
                            ),
                          );
                        }(),
                      ],
                    ),
                  ).animate().fadeIn(duration: 200.ms),
              ],
            );
          },
        ),
      ),
    );
  }

  // Bottom Area (Input Container + Disclaimer Text)
  Widget _buildBottomInputArea(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPillInputBox(context),
        const SizedBox(height: 6),
        Text(
          'Oreo AI Tutor can make mistakes. Check important info.',
          style: TextStyle(fontSize: 11, color: colors.fgSecondary),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ChatGPT Sleek Pill Input Box Widget (Dynamically toggles Send button vs Voice buttons)
  Widget _buildPillInputBox(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.borderSubtle, width: 1),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attached File Preview Chips
          if (_attachedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 2),
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _attachedFiles.map((f) => _buildAttachedFileChip(context, f, isDismissible: true)).toList(),
              ),
            ),

          // Input Controls Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                // Left Attachment Popup Button (+)
                PopupMenuButton<String>(
                  icon: Icon(Icons.add_rounded, color: colors.fgSecondary, size: 22),
                  color: colors.bgElevated,
                  tooltip: 'Attach PDF, DOCX, MD, or Images',
                  onSelected: (value) {
                    if (value == 'file') _pickFiles();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'file',
                      child: Row(
                        children: [
                          Icon(Icons.file_present_outlined, color: colors.fgAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Upload Document (PDF, DOCX, MD)', style: TextStyle(color: colors.fgPrimary, fontSize: 13))),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'file',
                      child: Row(
                        children: [
                          Icon(Icons.image_outlined, color: colors.accentEmerald, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Upload Image / Screenshot', style: TextStyle(color: colors.fgPrimary, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                ),

                // Middle Text Field with Enter to send & Shift+Enter for multiline
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(color: colors.fgPrimary, fontSize: 15),
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      hintText: widget.isWorkspaceMode && ref.watch(activeWorkspaceProvider)?.activeLearningContext != null
                          ? 'Ask about ${ref.watch(activeWorkspaceProvider)!.activeLearningContext}...'
                          : 'Ask anything or type your learning goal...',
                      hintStyle: TextStyle(color: colors.fgSecondary, fontSize: 14),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),

                // DYNAMIC RIGHT BUTTONS: If user typed text or attached files -> Show Send Button (↑)
                // Otherwise -> Show Dictation Mic (🎤) + Live Voice Assistant (🎙️/🔊)
                if (_canSend)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_upward_rounded, color: colors.fgInverse, size: 18),
                    ),
                    tooltip: 'Send message',
                    onPressed: () => _handleUserMessage(_inputController.text),
                  )
                else ...[
                  // Right Dictation Mic Button (🎤)
                  IconButton(
                    icon: Icon(Icons.mic_none_rounded, color: colors.fgSecondary, size: 20),
                    tooltip: 'Voice Dictation',
                    onPressed: () {
                      _voiceService.startListening(
                        onRecognizedText: (text) {
                          _inputController.text = text;
                        },
                      );
                    },
                  ),

                  // Right Live Voice Assistant Circular Button (🎙️ / 🔊)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.graphic_eq_rounded, color: colors.fgInverse, size: 16),
                    ),
                    tooltip: 'Live Voice Assistant Mode',
                    onPressed: _toggleVoiceAssistantModal,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Minimal Action Row Icon Button
  Widget _buildIconActionButton(BuildContext context, IconData icon, String tooltip, VoidCallback onTap) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 16, color: colors.fgSecondary),
        ),
      ),
    );
  }

  // Quick Action Row Item
  Widget _buildQuickActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.fgSecondary, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: colors.fgSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Attached File Chip Component
  Widget _buildAttachedFileChip(BuildContext context, AttachedFileModel file, {required bool isDismissible}) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            file.isImage ? Icons.image_outlined : Icons.description_outlined,
            size: 14,
            color: colors.fgAccent,
          ),
          const SizedBox(width: 6),
          Text(
            file.name,
            style: TextStyle(fontSize: 12, color: colors.fgPrimary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            '(${file.formattedSize})',
            style: TextStyle(fontSize: 10, color: colors.fgSecondary),
          ),
          if (isDismissible) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _removeFile(file.id),
              child: const Icon(Icons.close_rounded, size: 14, color: AppColors.fgSecondary),
            ),
          ],
        ],
      ),
    );
  }

  // Live Voice Assistant Modal Overlay
  Widget _buildVoiceAssistantModal(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Oreo Live Voice Assistant',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Listening for your spoken interview answers...',
                style: TextStyle(fontSize: 14, color: AppColors.fgSecondary),
              ),
              const SizedBox(height: 48),

              // Animated Sound Wave Spectrum Bar
              StreamBuilder<List<double>>(
                stream: _voiceService.waveformStream,
                initialData: List.generate(24, (_) => 0.2),
                builder: (context, snapshot) {
                  final bars = snapshot.data ?? List.generate(24, (_) => 0.2);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: bars.map((heightFactor) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 70),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 5,
                        height: 20 + (heightFactor * 60),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 48),

              // Close Voice Mode Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgElevated,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.close_rounded, color: AppColors.fgPrimary),
                label: const Text('End Voice Session', style: TextStyle(color: AppColors.fgPrimary, fontWeight: FontWeight.bold)),
                onPressed: _toggleVoiceAssistantModal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// High-performance on-the-go streaming Markdown renderer.
/// Incrementally renders formatted Markdown text with snappy typing speed.
class StreamingMarkdownBody extends StatefulWidget {
  final String text;
  final MarkdownStyleSheet styleSheet;
  final VoidCallback? onFinished;
  final VoidCallback? onTick;

  const StreamingMarkdownBody({
    super.key,
    required this.text,
    required this.styleSheet,
    this.onFinished,
    this.onTick,
  });

  @override
  State<StreamingMarkdownBody> createState() => _StreamingMarkdownBodyState();
}

class _StreamingMarkdownBodyState extends State<StreamingMarkdownBody> {
  Timer? _timer;
  int _charIndex = 0;
  late int _chunkSize;

  @override
  void initState() {
    super.initState();
    // Dynamically scale chunk size so the entire reply loads quickly (0.8s - 1.4s max)
    // while feeling like a natural, rapid AI stream.
    _chunkSize = (widget.text.length / 50).ceil().clamp(3, 16);
    _startStreaming();
  }

  void _startStreaming() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 12), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _charIndex += _chunkSize;
        if (_charIndex >= widget.text.length) {
          _charIndex = widget.text.length;
          timer.cancel();
          widget.onFinished?.call();
        }
      });
      widget.onTick?.call();
    });
  }

  void _skipToEnd() {
    if (_charIndex < widget.text.length) {
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _charIndex = widget.text.length;
        });
        widget.onFinished?.call();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.text.substring(0, _charIndex);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skipToEnd,
      child: MarkdownBody(
        data: currentText,
        styleSheet: widget.styleSheet,
      ),
    );
  }
}

