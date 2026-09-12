import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../models/block_type.dart';
import '../../models/note_block_model.dart';
import '../../models/note_page_model.dart';
import '../../providers/notes_provider.dart';
import 'block_item_widget.dart';
import 'slash_command_menu.dart';

class NotesEditor extends ConsumerStatefulWidget {
  final NotePage page;

  const NotesEditor({super.key, required this.page});

  @override
  ConsumerState<NotesEditor> createState() => _NotesEditorState();
}

class _NotesEditorState extends ConsumerState<NotesEditor> {
  late TextEditingController _titleController;
  final Map<String, TextEditingController> _blockControllers = {};
  final Map<String, FocusNode> _blockFocusNodes = {};

  bool _isSlashMenuOpen = false;
  String _slashFilter = '';
  int _slashBlockIndex = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.page.title);
    _syncBlockControllers(widget.page.blocks);
  }

  @override
  void didUpdateWidget(NotesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.id != widget.page.id) {
      _titleController.text = widget.page.title;
      _disposeBlockControllers();
      _syncBlockControllers(widget.page.blocks);
      _isSlashMenuOpen = false;
    } else if (oldWidget.page.blocks.length != widget.page.blocks.length) {
      _syncBlockControllers(widget.page.blocks);
    } else {
      // Sync content if changed externally
      for (final b in widget.page.blocks) {
        if (_blockControllers.containsKey(b.id) &&
            _blockControllers[b.id]!.text != b.content &&
            !_blockFocusNodes[b.id]!.hasFocus) {
          _blockControllers[b.id]!.text = b.content;
        }
      }
    }
  }

  void _syncBlockControllers(List<NoteBlock> blocks) {
    for (final block in blocks) {
      if (!_blockControllers.containsKey(block.id)) {
        _blockControllers[block.id] = TextEditingController(text: block.content);
        _blockFocusNodes[block.id] = FocusNode();
      }
    }
  }

  void _disposeBlockControllers() {
    for (final c in _blockControllers.values) {
      c.dispose();
    }
    for (final f in _blockFocusNodes.values) {
      f.dispose();
    }
    _blockControllers.clear();
    _blockFocusNodes.clear();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _disposeBlockControllers();
    super.dispose();
  }

  void _handleEnterPressed(int index) {
    final notifier = ref.read(notesNotifierProvider.notifier);
    notifier.addBlock(
      type: BlockType.paragraph,
      atIndex: index + 1,
      initialContent: '',
    );

    // Focus newly inserted block on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updatedPage = ref.read(notesNotifierProvider).activePage;
      if (updatedPage != null && index + 1 < updatedPage.blocks.length) {
        final newBlock = updatedPage.blocks[index + 1];
        _blockFocusNodes[newBlock.id]?.requestFocus();
      }
    });
  }

  void _handleBackspaceOnEmpty(int index) {
    if (widget.page.blocks.length <= 1) return;

    final currentBlock = widget.page.blocks[index];
    final notifier = ref.read(notesNotifierProvider.notifier);

    // Delete current block and focus previous
    notifier.deleteBlock(currentBlock.id);

    if (index > 0) {
      final prevBlock = widget.page.blocks[index - 1];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _blockFocusNodes[prevBlock.id]?.requestFocus();
      });
    }
  }

  void _handleSlashTriggered(int index, String filter) {
    setState(() {
      _isSlashMenuOpen = true;
      _slashFilter = filter;
      _slashBlockIndex = index;
    });
  }

  void _handleSelectSlashCommand(SlashCommandItem item) {
    setState(() {
      _isSlashMenuOpen = false;
    });

    if (item.blockType == null) return;

    final block = widget.page.blocks[_slashBlockIndex];
    final controller = _blockControllers[block.id];

    // Clean slash command query from text
    if (controller != null) {
      String cleanText = controller.text;
      if (cleanText.contains('/')) {
        final slashIndex = cleanText.lastIndexOf('/');
        cleanText = cleanText.substring(0, slashIndex).trim();
      }
      controller.text = cleanText;
      ref.read(notesNotifierProvider.notifier).updateBlockContent(block.id, cleanText);
    }

    // Change block type
    ref.read(notesNotifierProvider.notifier).turnBlockInto(block.id, item.blockType!);
    if (item.defaultMetadata != null) {
      ref.read(notesNotifierProvider.notifier).updateBlockMetadata(block.id, item.defaultMetadata!);
    }

    _blockFocusNodes[block.id]?.requestFocus();
  }

  String _formatLastEdited(DateTime? dt) {
    if (dt == null) return 'Edited just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Edited just now';
    if (diff.inMinutes < 60) return 'Edited ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Edited ${diff.inHours}h ago';
    return 'Edited ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notesState = ref.watch(notesNotifierProvider);
    final allPages = notesState.pages;

    // Build breadcrumbs
    final List<String> breadcrumbs = ['Workspace'];
    if (widget.page.parentPageId != null) {
      final parent = allPages.where((p) => p.id == widget.page.parentPageId).firstOrNull;
      if (parent != null) {
        breadcrumbs.add(parent.title.isEmpty ? 'Untitled' : parent.title);
      }
    }
    breadcrumbs.add(widget.page.title.isEmpty ? 'Untitled' : widget.page.title);

    int numberedListCounter = 1;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        // Main Editor Canvas (Top-aligned, Left-aligned, Document-width)
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 16, 40, 60),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb & Status Bar
                  Row(
                    children: [
                      ...List.generate(breadcrumbs.length * 2 - 1, (i) {
                        if (i.isOdd) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.chevron_right_rounded, size: 14, color: colors.fgSecondary),
                          );
                        }
                        final crumb = breadcrumbs[i ~/ 2];
                        final isLast = i == breadcrumbs.length * 2 - 2;
                        return Text(
                          crumb,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                            color: isLast ? colors.fgPrimary : colors.fgSecondary,
                          ),
                        );
                      }),
                      const Spacer(),

                      // Auto-save indicator
                      if (notesState.isSaving)
                        Row(
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: colors.accentPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Saving...',
                              style: TextStyle(fontSize: 11, color: colors.fgSecondary),
                            ),
                          ],
                        )
                      else
                        Text(
                          _formatLastEdited(widget.page.updatedAt),
                          style: TextStyle(fontSize: 11, color: colors.fgSecondary.withValues(alpha: 0.8)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Page Title & Material Icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.bgActivityBar,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          size: 22,
                          color: colors.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          onChanged: (val) {
                            ref.read(notesNotifierProvider.notifier).updatePageTitle(val);
                          },
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colors.fgPrimary,
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Untitled Page',
                            hintStyle: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colors.fgSecondary.withValues(alpha: 0.35),
                              letterSpacing: -0.5,
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: colors.borderSubtle, thickness: 1.0, height: 1.0),
                  const SizedBox(height: 16),

                  // Blocks List
                  ...List.generate(widget.page.blocks.length, (index) {
                    final block = widget.page.blocks[index];
                    final controller = _blockControllers[block.id] ?? TextEditingController(text: block.content);
                    final focusNode = _blockFocusNodes[block.id] ?? FocusNode();

                    if (block.type == BlockType.numberedList) {
                      if (index == 0 || widget.page.blocks[index - 1].type != BlockType.numberedList) {
                        numberedListCounter = 1;
                      } else {
                        numberedListCounter++;
                      }
                    }

                    return BlockItemWidget(
                      key: ValueKey(block.id),
                      block: block,
                      index: index,
                      listNumber: numberedListCounter,
                      controller: controller,
                      focusNode: focusNode,
                      onContentChanged: (val) {
                        ref.read(notesNotifierProvider.notifier).updateBlockContent(block.id, val);
                      },
                      onEnterPressed: () => _handleEnterPressed(index),
                      onBackspaceOnEmpty: () => _handleBackspaceOnEmpty(index),
                      onSlashTriggered: (query) => _handleSlashTriggered(index, query),
                      onTurnInto: (newType) {
                        ref.read(notesNotifierProvider.notifier).turnBlockInto(block.id, newType);
                      },
                      onDuplicate: () {
                        ref.read(notesNotifierProvider.notifier).duplicateBlock(block.id);
                      },
                      onDelete: () {
                        ref.read(notesNotifierProvider.notifier).deleteBlock(block.id);
                      },
                      onMoveUp: () {
                        ref.read(notesNotifierProvider.notifier).moveBlockUp(block.id);
                      },
                      onMoveDown: () {
                        ref.read(notesNotifierProvider.notifier).moveBlockDown(block.id);
                      },
                      onMetadataChanged: (meta) {
                        ref.read(notesNotifierProvider.notifier).updateBlockMetadata(block.id, meta);
                      },
                    );
                  }),

                  // Bottom Quick Insert Trigger Area
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () {
                      _handleEnterPressed(widget.page.blocks.length - 1);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 16, color: colors.fgSecondary.withValues(alpha: 0.6)),
                          const SizedBox(width: 8),
                          Text(
                            'Click or press Enter to add next block...',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.fgSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Popover Slash Command Menu
        if (_isSlashMenuOpen)
          Positioned(
            left: 80,
            top: 140,
            child: SlashCommandMenu(
              filterText: _slashFilter,
              onSelectCommand: _handleSelectSlashCommand,
              onDismiss: () {
                setState(() => _isSlashMenuOpen = false);
              },
            ),
          ),
      ],
    );
  }
}
