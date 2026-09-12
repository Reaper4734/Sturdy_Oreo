import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_theme.dart';
import '../../models/block_type.dart';

class SlashCommandItem {
  final String title;
  final String description;
  final IconData icon;
  final BlockType? blockType;
  final Map<String, dynamic>? defaultMetadata;
  final bool isAiPlaceholder;

  const SlashCommandItem({
    required this.title,
    required this.description,
    required this.icon,
    this.blockType,
    this.defaultMetadata,
    this.isAiPlaceholder = false,
  });
}

class SlashCommandMenu extends StatefulWidget {
  final String filterText;
  final ValueChanged<SlashCommandItem> onSelectCommand;
  final VoidCallback onDismiss;

  const SlashCommandMenu({
    super.key,
    required this.filterText,
    required this.onSelectCommand,
    required this.onDismiss,
  });

  @override
  State<SlashCommandMenu> createState() => _SlashCommandMenuState();
}

class _SlashCommandMenuState extends State<SlashCommandMenu> {
  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  static const List<SlashCommandItem> _allItems = [
    // Standard Blocks
    SlashCommandItem(
      title: 'Text',
      description: 'Just start writing with plain text',
      icon: Icons.notes_rounded,
      blockType: BlockType.paragraph,
    ),
    SlashCommandItem(
      title: 'Heading 1',
      description: 'Large section heading',
      icon: Icons.title_rounded,
      blockType: BlockType.heading1,
    ),
    SlashCommandItem(
      title: 'Heading 2',
      description: 'Medium section heading',
      icon: Icons.format_size_rounded,
      blockType: BlockType.heading2,
    ),
    SlashCommandItem(
      title: 'Heading 3',
      description: 'Small subsection heading',
      icon: Icons.text_fields_rounded,
      blockType: BlockType.heading3,
    ),
    SlashCommandItem(
      title: 'To-do List',
      description: 'Track tasks with a checklist',
      icon: Icons.check_box_outlined,
      blockType: BlockType.checklist,
      defaultMetadata: {'checked': false},
    ),
    SlashCommandItem(
      title: 'Bulleted List',
      description: 'Create a simple bulleted list',
      icon: Icons.format_list_bulleted_rounded,
      blockType: BlockType.bulletList,
    ),
    SlashCommandItem(
      title: 'Numbered List',
      description: 'Create an ordered list with numbering',
      icon: Icons.format_list_numbered_rounded,
      blockType: BlockType.numberedList,
    ),
    SlashCommandItem(
      title: 'Callout (Info)',
      description: 'Highlight important info with blue background',
      icon: Icons.info_outline_rounded,
      blockType: BlockType.callout,
      defaultMetadata: {'calloutType': 'info'},
    ),
    SlashCommandItem(
      title: 'Callout (Tip)',
      description: 'Highlight helpful tips with emerald green',
      icon: Icons.lightbulb_outline_rounded,
      blockType: BlockType.callout,
      defaultMetadata: {'calloutType': 'tip'},
    ),
    SlashCommandItem(
      title: 'Callout (Warning)',
      description: 'Caution alert with amber background',
      icon: Icons.warning_amber_rounded,
      blockType: BlockType.callout,
      defaultMetadata: {'calloutType': 'warning'},
    ),
    SlashCommandItem(
      title: 'Callout (Important)',
      description: 'Critical notice with rose red background',
      icon: Icons.error_outline_rounded,
      blockType: BlockType.callout,
      defaultMetadata: {'calloutType': 'important'},
    ),
    SlashCommandItem(
      title: 'Code Block',
      description: 'Code snippet with monospace & copy button',
      icon: Icons.code_rounded,
      blockType: BlockType.code,
      defaultMetadata: {'language': 'java'},
    ),
    SlashCommandItem(
      title: 'Quote',
      description: 'Capture a quote or key takeaway',
      icon: Icons.format_quote_rounded,
      blockType: BlockType.quote,
    ),
    SlashCommandItem(
      title: 'Divider',
      description: 'Visually divide sections with a line',
      icon: Icons.horizontal_rule_rounded,
      blockType: BlockType.divider,
    ),
    SlashCommandItem(
      title: 'Image',
      description: 'Embed an image with caption',
      icon: Icons.image_outlined,
      blockType: BlockType.image,
      defaultMetadata: {'url': '', 'caption': ''},
    ),

    // Future AI Placeholders (Strictly Phase 4 placeholders, non-functional)
    SlashCommandItem(
      title: 'Ask AI (Coming in Phase 4)',
      description: 'Ask AI tutor to explain or expand concepts',
      icon: Icons.auto_awesome_rounded,
      isAiPlaceholder: true,
    ),
    SlashCommandItem(
      title: 'Create Diagram (Coming in Phase 4)',
      description: 'Generate conceptual architecture diagrams',
      icon: Icons.schema_outlined,
      isAiPlaceholder: true,
    ),
    SlashCommandItem(
      title: 'Summarize Notes (Coming in Phase 4)',
      description: 'Generate concise executive summary',
      icon: Icons.summarize_outlined,
      isAiPlaceholder: true,
    ),
  ];

  List<SlashCommandItem> get _filteredItems {
    final query = widget.filterText.trim().toLowerCase();
    if (query.isEmpty) return _allItems;
    return _allItems.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(SlashCommandMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterText != widget.filterText) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final filtered = _filteredItems;
    if (filtered.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % filtered.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + filtered.length) % filtered.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < filtered.length) {
        final item = filtered[_selectedIndex];
        if (!item.isAiPlaceholder) {
          widget.onSelectCommand(item);
        }
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _filteredItems;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 340),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.bgActivityBar,
                  border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.terminal_rounded, size: 14, color: colors.accentPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Insert Block',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.fgSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ESC to cancel',
                      style: TextStyle(fontSize: 10, color: colors.fgSecondary),
                    ),
                  ],
                ),
              ),

              // Items List
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No matching blocks found',
                      style: TextStyle(color: colors.fgSecondary, fontSize: 12),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = index == _selectedIndex;

                      return InkWell(
                        onTap: item.isAiPlaceholder
                            ? null
                            : () => widget.onSelectCommand(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.accentPrimary.withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.accentPrimary.withValues(alpha: 0.2)
                                      : colors.bgActivityBar,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                                  ),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 16,
                                  color: item.isAiPlaceholder
                                      ? colors.fgSecondary
                                      : (isSelected ? colors.accentPrimary : colors.fgPrimary),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: item.isAiPlaceholder ? colors.fgSecondary : colors.fgPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.description,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colors.fgSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
