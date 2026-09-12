import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../models/note_block_model.dart';

class CodeBlockWidget extends StatefulWidget {
  final NoteBlock block;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onLanguageChanged;

  const CodeBlockWidget({
    super.key,
    required this.block,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onLanguageChanged,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _copied = false;

  static const List<String> _languages = [
    'java',
    'python',
    'dart',
    'javascript',
    'typescript',
    'sql',
    'c++',
    'go',
    'rust',
    'html',
    'json',
    'bash',
  ];

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.controller.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final language = (widget.block.metadata['language'] as String? ?? 'java').toLowerCase();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Language Selector and Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgActivityBar,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
            ),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Change language',
                  onSelected: widget.onLanguageChanged,
                  itemBuilder: (context) => _languages.map((lang) {
                    return PopupMenuItem(
                      value: lang,
                      child: Text(
                        lang.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: lang == language ? FontWeight.bold : FontWeight.normal,
                          color: lang == language ? colors.accentPrimary : colors.fgPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.accentPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          language.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors.accentPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 16, color: colors.fgSecondary),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 14,
                          color: _copied ? colors.accentEmerald : colors.fgSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied' : 'Copy',
                          style: TextStyle(
                            fontSize: 11,
                            color: _copied ? colors.accentEmerald : colors.fgSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Monospace Code Editor
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                letterSpacing: 0.3,
              ),
              decoration: InputDecoration(
                hintText: '// Write or paste code snippet here...',
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: colors.fgSecondary.withValues(alpha: 0.6),
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
    );
  }
}
