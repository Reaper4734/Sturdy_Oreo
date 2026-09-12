import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_theme.dart';
import '../../models/block_type.dart';
import '../../models/note_block_model.dart';
import 'block_renderers/callout_block_widget.dart';
import 'block_renderers/checklist_block_widget.dart';
import 'block_renderers/code_block_widget.dart';
import 'block_renderers/divider_block_widget.dart';
import 'block_renderers/image_block_widget.dart';
import 'block_renderers/quote_block_widget.dart';

class BlockItemWidget extends StatefulWidget {
  final NoteBlock block;
  final int index;
  final int listNumber; // for numbered lists
  final FocusNode focusNode;
  final TextEditingController controller;
  final ValueChanged<String> onContentChanged;
  final VoidCallback onEnterPressed;
  final VoidCallback onBackspaceOnEmpty;
  final ValueChanged<String> onSlashTriggered;
  final ValueChanged<BlockType> onTurnInto;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final ValueChanged<Map<String, dynamic>> onMetadataChanged;

  const BlockItemWidget({
    super.key,
    required this.block,
    required this.index,
    this.listNumber = 1,
    required this.focusNode,
    required this.controller,
    required this.onContentChanged,
    required this.onEnterPressed,
    required this.onBackspaceOnEmpty,
    required this.onSlashTriggered,
    required this.onTurnInto,
    required this.onDuplicate,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onMetadataChanged,
  });

  @override
  State<BlockItemWidget> createState() => _BlockItemWidgetState();
}

class _BlockItemWidgetState extends State<BlockItemWidget> {
  bool _isHovered = false;

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed &&
        widget.block.type != BlockType.code) {
      widget.onEnterPressed();
    } else if (event.logicalKey == LogicalKeyboardKey.backspace &&
        widget.controller.text.isEmpty) {
      widget.onBackspaceOnEmpty();
    }
  }

  void _onTextChanged(String val) {
    widget.onContentChanged(val);
    if (val.endsWith('/')) {
      widget.onSlashTriggered('');
    } else if (val.contains('/')) {
      final lastSlash = val.lastIndexOf('/');
      final query = val.substring(lastSlash + 1);
      if (!query.contains(' ') && query.length < 15) {
        widget.onSlashTriggered(query);
      }
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final colors = context.colors;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      color: colors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.borderSubtle),
      ),
      items: [
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 16, color: colors.fgSecondary),
              const SizedBox(width: 10),
              const Text('Duplicate', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'move_up',
          child: Row(
            children: [
              Icon(Icons.arrow_upward_rounded, size: 16, color: colors.fgSecondary),
              const SizedBox(width: 10),
              const Text('Move Up', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'move_down',
          child: Row(
            children: [
              Icon(Icons.arrow_downward_rounded, size: 16, color: colors.fgSecondary),
              const SizedBox(width: 10),
              const Text('Move Down', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItemGroup(
          text: 'Turn into...',
          children: [
            _buildTurnIntoItem('Text', BlockType.paragraph, Icons.notes_rounded, colors),
            _buildTurnIntoItem('Heading 1', BlockType.heading1, Icons.title_rounded, colors),
            _buildTurnIntoItem('Heading 2', BlockType.heading2, Icons.format_size_rounded, colors),
            _buildTurnIntoItem('Heading 3', BlockType.heading3, Icons.text_fields_rounded, colors),
            _buildTurnIntoItem('To-do List', BlockType.checklist, Icons.check_box_outlined, colors),
            _buildTurnIntoItem('Bulleted List', BlockType.bulletList, Icons.format_list_bulleted_rounded, colors),
            _buildTurnIntoItem('Numbered List', BlockType.numberedList, Icons.format_list_numbered_rounded, colors),
            _buildTurnIntoItem('Callout', BlockType.callout, Icons.lightbulb_outline_rounded, colors),
            _buildTurnIntoItem('Code Block', BlockType.code, Icons.code_rounded, colors),
            _buildTurnIntoItem('Quote', BlockType.quote, Icons.format_quote_rounded, colors),
          ],
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: colors.accentRose),
              const SizedBox(width: 10),
              Text('Delete', style: TextStyle(fontSize: 13, color: colors.accentRose)),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (val == null) return;
      if (val == 'duplicate') widget.onDuplicate();
      if (val == 'move_up') widget.onMoveUp();
      if (val == 'move_down') widget.onMoveDown();
      if (val == 'delete') widget.onDelete();
      if (val.startsWith('turn_')) {
        final key = val.substring(5);
        widget.onTurnInto(BlockType.fromKey(key));
      }
    });
  }

  PopupMenuEntry<String> _buildTurnIntoItem(String label, BlockType type, IconData icon, AppColorsExtension colors) {
    return PopupMenuItem<String>(
      value: 'turn_${type.key}',
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 15, color: colors.fgSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: _handleKeyEvent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hover Drag Handle ⋮⋮
              SizedBox(
                width: 28,
                height: 28,
                child: AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: GestureDetector(
                    onTapDown: (details) {
                      _showContextMenu(context, details.globalPosition);
                    },
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _isHovered ? colors.bgActivityBar : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          size: 18,
                          color: colors.fgSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Main Block Content
              Expanded(
                child: _buildBlockContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _documentInputDecoration({
    required String hintText,
    required TextStyle hintStyle,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: hintStyle,
      filled: false,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      isDense: true,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(vertical: 2),
    );
  }

  Widget _buildBlockContent(BuildContext context) {
    final colors = context.colors;

    switch (widget.block.type) {
      case BlockType.heading1:
        return TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: _onTextChanged,
          maxLines: null,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.fgPrimary,
            height: 1.3,
            letterSpacing: -0.4,
          ),
          decoration: _documentInputDecoration(
            hintText: 'Heading 1',
            hintStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.fgSecondary.withValues(alpha: 0.35),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
        );

      case BlockType.heading2:
        return TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: _onTextChanged,
          maxLines: null,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: colors.fgPrimary,
            height: 1.35,
          ),
          decoration: _documentInputDecoration(
            hintText: 'Heading 2',
            hintStyle: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: colors.fgSecondary.withValues(alpha: 0.35),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 3),
          ),
        );

      case BlockType.heading3:
        return TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: _onTextChanged,
          maxLines: null,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.fgPrimary,
            height: 1.4,
          ),
          decoration: _documentInputDecoration(
            hintText: 'Heading 3',
            hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.fgSecondary.withValues(alpha: 0.35),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 2),
          ),
        );

      case BlockType.bulletList:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.fgPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: _onTextChanged,
                maxLines: null,
                style: TextStyle(fontSize: 14, height: 1.5, color: colors.fgPrimary),
                decoration: _documentInputDecoration(
                  hintText: 'List item...',
                  hintStyle: TextStyle(color: colors.fgSecondary.withValues(alpha: 0.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                ),
              ),
            ),
          ],
        );

      case BlockType.numberedList:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: Text(
                '${widget.listNumber}.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.fgSecondary,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: _onTextChanged,
                maxLines: null,
                style: TextStyle(fontSize: 14, height: 1.5, color: colors.fgPrimary),
                decoration: _documentInputDecoration(
                  hintText: 'List item...',
                  hintStyle: TextStyle(color: colors.fgSecondary.withValues(alpha: 0.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                ),
              ),
            ),
          ],
        );

      case BlockType.checklist:
        return ChecklistBlockWidget(
          block: widget.block,
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: _onTextChanged,
          onToggleChecked: (val) {
            widget.onMetadataChanged({'checked': val});
          },
        );

      case BlockType.quote:
        return QuoteBlockWidget(
          block: widget.block,
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: _onTextChanged,
        );

      case BlockType.callout:
        return CalloutBlockWidget(
          block: widget.block,
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: _onTextChanged,
          onTypeChanged: (type) {
            widget.onMetadataChanged({'calloutType': type});
          },
        );

      case BlockType.code:
        return CodeBlockWidget(
          block: widget.block,
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: _onTextChanged,
          onLanguageChanged: (lang) {
            widget.onMetadataChanged({'language': lang});
          },
        );

      case BlockType.divider:
        return const DividerBlockWidget();

      case BlockType.image:
        return ImageBlockWidget(
          block: widget.block,
          onUrlChanged: (url) {
            widget.onMetadataChanged({'url': url});
          },
          onCaptionChanged: (cap) {
            widget.onMetadataChanged({'caption': cap});
          },
        );

      case BlockType.paragraph:
        return TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: _onTextChanged,
          maxLines: null,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: colors.fgPrimary,
          ),
          decoration: _documentInputDecoration(
            hintText: "Type '/' for commands...",
            hintStyle: TextStyle(
              fontSize: 14,
              color: colors.fgSecondary.withValues(alpha: 0.45),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 2),
          ),
        );
    }
  }
}

class PopupMenuItemGroup extends PopupMenuEntry<Never> {
  final String text;
  final List<PopupMenuEntry<String>> children;

  const PopupMenuItemGroup({super.key, required this.text, required this.children});

  @override
  double get height => 24.0 + (children.length * 36.0);

  @override
  bool represents(Never? value) => false;

  @override
  State<PopupMenuItemGroup> createState() => _PopupMenuItemGroupState();
}

class _PopupMenuItemGroupState extends State<PopupMenuItemGroup> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.fgSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        ...widget.children,
      ],
    );
  }
}
