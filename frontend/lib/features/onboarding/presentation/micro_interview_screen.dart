import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/models/micro_interview_model.dart';
import '../../../shared/models/workspace_model.dart';
import '../../../shared/providers/workspace_providers.dart';
import '../../../shared/repositories/http_interview_repository.dart';
import '../../../shared/services/file_picker_service.dart';
import '../../../shared/services/voice_assistant_service.dart';
import '../../dashboard/data/mock_dashboard_data.dart';
import '../../workspace/data/http_workspace_repository.dart';
import 'widgets/workspace_generation_interstitial.dart';

class MicroInterviewScreen extends ConsumerStatefulWidget {
  final VoidCallback onInterviewComplete;
  final bool showHeader;

  const MicroInterviewScreen({
    super.key,
    required this.onInterviewComplete,
    this.showHeader = true,
  });

  @override
  ConsumerState<MicroInterviewScreen> createState() => _MicroInterviewScreenState();
}

class _MicroInterviewScreenState extends ConsumerState<MicroInterviewScreen> {
  final FilePickerService _filePickerService = FilePickerService();
  final VoiceAssistantService _voiceService = VoiceAssistantService();

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  final List<AttachedFileModel> _attachedFiles = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showVoiceModal = false;
  bool _isGeneratingWorkspace = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onTextChanged);
    _loadInitialMessages();
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to toggle Send vs Mic/Voice button dynamically
  }

  @override
  void dispose() {
    _inputController.removeListener(_onTextChanged);
    _voiceService.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    final activeWs = ref.read(activeWorkspaceProvider);
    if (activeWs != null && activeWs.chatHistory.isNotEmpty) {
      if (mounted) {
        setState(() {
          _messages = List.from(activeWs.chatHistory);
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final repo = ref.read(httpInterviewRepositoryProvider);
      final initialMsg = await repo.sendUserResponse("Start the interview", "");
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
    if (activeWs != null) {
      activeWs.chatHistory = List.from(_messages);
      ref.read(workspaceListProvider.notifier).touchWorkspace(activeWs.id);

      // Conversational Workspace Editing
      if (text.toLowerCase().contains('already know') || text.toLowerCase().contains('master')) {
        activeWs.progressPercent = (activeWs.progressPercent + 0.15).clamp(0.0, 1.0);
        triggerAutoSaveFeedback(ref);
      }
    }

    _inputController.clear();
    _scrollToBottom();

    // Check if we are in the temporary Knowledge Hub -> Workspace flow
    bool isKnowledgeHubFlow = activeWs != null && 
        _messages.isNotEmpty &&
        _messages.first.text.contains("I've prepared your");
        
    ChatMessage? mockReply;

    if (isKnowledgeHubFlow && _messages.length == 2) {
      await Future.delayed(const Duration(milliseconds: 1500));
      final lowerText = text.toLowerCase();
      if (lowerText.contains('continue')) {
        mockReply = ChatMessage(
          id: 'ai_kh_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'AI',
          text: "Loading course...\n\nBackend Search Engine...\nCourse Loaded...\n\nWorkspace Ready.",
        );
      } else {
        try {
          final repo = ref.read(httpWorkspaceRepositoryProvider);
          final updatedWs = await repo.updateRoadmap(activeWs, text);
          
          ref.read(workspaceListProvider.notifier).updateWorkspace(updatedWs);
          
          mockReply = ChatMessage(
            id: 'ai_kh_${DateTime.now().millisecondsSinceEpoch}',
            sender: 'AI',
            text: "Done. I've updated your learning path. Check out the updated roadmap!",
          );
        } catch (e) {
          mockReply = ChatMessage(
            id: 'ai_kh_${DateTime.now().millisecondsSinceEpoch}',
            sender: 'AI',
            text: "Sorry, I failed to update the roadmap: $e",
          );
        }
      }
    }

    final repo = ref.read(httpInterviewRepositoryProvider);
    final historyStr = _messages.map((m) => "${m.sender}: ${m.text}").join("\n");
    final aiReply = mockReply ?? await repo.sendUserResponse(text, historyStr, files: sentFiles);

    if (mounted) {
      setState(() {
        _messages.add(aiReply);
        _isSending = false;
      });
      if (activeWs != null) {
        activeWs.chatHistory = List.from(_messages);
      }
      _scrollToBottom();
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

  bool get _hasUserInteracted => _messages.any((m) => m.sender == 'USER');

  bool get _canSend => _inputController.text.trim().isNotEmpty || _attachedFiles.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    ref.listen(activeWorkspaceProvider, (previous, next) {
      if (next != null && (previous == null || previous.id != next.id)) {
        setState(() {
          _messages = List.from(next.chatHistory);
        });
      }
    });

    if (_isGeneratingWorkspace) {
      return WorkspaceGenerationInterstitial(
        topicName: 'Personalized Learning Curriculum',
        onCompleted: () async {
          WorkspaceModel? newWs;
          try {
             final repo = ref.read(httpWorkspaceRepositoryProvider);
             final lastAiMsg = _messages.reversed.firstWhere((m) => m.sender == 'AI', orElse: () => _messages.last);
             final metadata = lastAiMsg.metadata ?? {};
             final personaStr = "Domain: ${metadata['domain_identified']}, Score: ${metadata['confidence_score']}";
             
             newWs = await repo.createWorkspaceFromCourse("Custom AI Curriculum", persona: personaStr);
             newWs.chatHistory = List.from(_messages);
          } catch(e) {
             print("Failed to generate real workspace, falling back: $e");
             final newId = 'ws_custom_${DateTime.now().millisecondsSinceEpoch}';
             newWs = WorkspaceModel(
               id: newId,
               userId: 'user_priyaj',
               title: 'Custom Learning Project',
               subject: 'Tailored Curriculum',
               difficulty: 'Intermediate',
               createdAt: DateTime.now(),
               lastOpened: DateTime.now(),
               progressPercent: 0.10,
               activeLearningContext: 'Core Fundamentals',
               flashcardCount: 45,
               roadmapNodeCount: 12,
               accentColor: const Color(0xFF67E8F9),
               chatHistory: List.from(_messages),
             );
          }
          
          if (newWs != null) {
            ref.read(workspaceListProvider.notifier).createWorkspace(newWs);
            ref.read(activeWorkspaceIdProvider.notifier).state = newWs.id;
          }

          if (mounted) {
            setState(() {
              _isGeneratingWorkspace = false;
            });
            widget.onInterviewComplete();
          }
        },
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bgCanvas,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
              : Column(
                  children: [
                    // Top Header Bar
                    if (widget.showHeader) _buildHeader(context),

                    // Main Viewport (ChatGPT Landing vs Active Unboxed Chat Thread)
                    Expanded(
                      child: Stack(
                        children: [
                          if (!_hasUserInteracted)
                            _buildChatGPTLandingState(context)
                          else
                            _buildActiveChatThread(context),
                        ],
                      ),
                    ),

                    // Bottom Floating Input Bar + Disclaimer (ONLY when user has started chatting)
                    if (_hasUserInteracted) _buildBottomInputArea(context),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgActivityBar,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'Oreo AI Tutor',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.fgSecondary, size: 18),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentEmerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircleAvatar(radius: 3, backgroundColor: AppColors.accentEmerald),
                SizedBox(width: 4),
                Text('Standalone Mock Active', style: TextStyle(fontSize: 10, color: AppColors.accentEmerald, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ChatGPT Centered Landing View State (Single Centered Input Bar)
  Widget _buildChatGPTLandingState(BuildContext context) {
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
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.fgPrimary),
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
                      children: msg.attachments!.map((f) => _buildAttachedFileChip(f, isDismissible: false)).toList(),
                    ),
                  ),

                // USER Message (Sleek Dark Pill) vs AI Message (Unboxed Text directly on Canvas)
                if (!isAI)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    constraints: const BoxConstraints(maxWidth: 550),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(msg.text, style: Theme.of(context).textTheme.bodyLarge),
                  ).animate().fadeIn(duration: 200.ms)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Unboxed AI Response Text
                        if (index == _messages.length - 1)
                          AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                msg.text,
                                textStyle: Theme.of(context).textTheme.bodyLarge!,
                                speed: const Duration(milliseconds: 20),
                              ),
                            ],
                            totalRepeatCount: 1,
                          )
                        else
                          Text(msg.text, style: Theme.of(context).textTheme.bodyLarge),

                        const SizedBox(height: 12),

                        // Action Bar Below AI Message (Copy, Like, Dislike, Share, Retry)
                        Row(
                          children: [
                            _buildIconActionButton(Icons.content_copy_outlined, 'Copy', () {
                              Clipboard.setData(ClipboardData(text: msg.text));
                            }),
                            const SizedBox(width: 4),
                            _buildIconActionButton(Icons.thumb_up_outlined, 'Good response', () {}),
                            const SizedBox(width: 4),
                            _buildIconActionButton(Icons.thumb_down_outlined, 'Bad response', () {}),
                            const SizedBox(width: 4),
                            _buildIconActionButton(Icons.refresh_rounded, 'Regenerate', () {}),
                            const SizedBox(width: 4),
                            _buildIconActionButton(Icons.more_horiz_rounded, 'More', () {}),
                          ],
                        ),

                        // Interactive Option Chips
                        if (msg.options != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: msg.options!.map((opt) {
                                final isNavCTA = opt.contains('➔');
                                return ActionChip(
                                  backgroundColor: isNavCTA ? AppColors.accentEmerald.withValues(alpha: 0.15) : AppColors.bgSurface,
                                  side: BorderSide(
                                    color: isNavCTA ? AppColors.accentEmerald : AppColors.borderSubtle,
                                  ),
                                  label: Text(
                                    opt,
                                    style: TextStyle(
                                      color: isNavCTA ? AppColors.accentEmerald : AppColors.fgPrimary,
                                      fontWeight: isNavCTA ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (isNavCTA) {
                                      setState(() {
                                        _isGeneratingWorkspace = true;
                                      });
                                    } else {
                                      _handleUserMessage(opt);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPillInputBox(context),
        const SizedBox(height: 6),
        const Text(
          'Oreo AI Tutor can make mistakes. Check important info.',
          style: TextStyle(fontSize: 11, color: AppColors.fgSecondary),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ChatGPT Sleek Pill Input Box Widget (Dynamically toggles Send button vs Voice buttons)
  Widget _buildPillInputBox(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
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
                children: _attachedFiles.map((f) => _buildAttachedFileChip(f, isDismissible: true)).toList(),
              ),
            ),

          // Input Controls Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                // Left Attachment Popup Button (+)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add_rounded, color: AppColors.fgSecondary, size: 22),
                  color: AppColors.bgElevated,
                  tooltip: 'Attach PDF, DOCX, MD, or Images',
                  onSelected: (value) {
                    if (value == 'file') _pickFiles();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'file',
                      child: Row(
                        children: [
                          Icon(Icons.file_present_outlined, color: AppColors.fgAccent, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text('Upload Document (PDF, DOCX, MD)', style: TextStyle(color: AppColors.fgPrimary, fontSize: 13))),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'file',
                      child: Row(
                        children: [
                          Icon(Icons.image_outlined, color: AppColors.accentEmerald, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text('Upload Image / Screenshot', style: TextStyle(color: AppColors.fgPrimary, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                ),

                // Middle Text Field
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: ref.watch(activeWorkspaceProvider)?.activeLearningContext != null
                          ? 'Ask about ${ref.watch(activeWorkspaceProvider)!.activeLearningContext}...'
                          : 'Ask anything',
                      hintStyle: const TextStyle(color: AppColors.fgSecondary, fontSize: 14),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    onSubmitted: _handleUserMessage,
                  ),
                ),

                // DYNAMIC RIGHT BUTTONS: If user typed text or attached files -> Show Send Button (↑)
                // Otherwise -> Show Dictation Mic (🎤) + Live Voice Assistant (🎙️/🔊)
                if (_canSend)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 18),
                    ),
                    tooltip: 'Send message',
                    onPressed: () => _handleUserMessage(_inputController.text),
                  )
                else ...[
                  // Right Dictation Mic Button (🎤)
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, color: AppColors.fgSecondary, size: 20),
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
                      decoration: const BoxDecoration(
                        color: AppColors.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 16),
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
  Widget _buildIconActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 16, color: AppColors.fgSecondary),
        ),
      ),
    );
  }

  // Quick Action Row Item
  Widget _buildQuickActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.fgSecondary, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.fgSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Attached File Chip Component
  Widget _buildAttachedFileChip(AttachedFileModel file, {required bool isDismissible}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            file.isImage ? Icons.image_outlined : Icons.description_outlined,
            size: 14,
            color: AppColors.fgAccent,
          ),
          const SizedBox(width: 6),
          Text(
            file.name,
            style: const TextStyle(fontSize: 12, color: AppColors.fgPrimary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            '(${file.formattedSize})',
            style: const TextStyle(fontSize: 10, color: AppColors.fgSecondary),
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
