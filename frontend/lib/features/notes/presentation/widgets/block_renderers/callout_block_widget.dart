import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../models/note_block_model.dart';

class CalloutBlockWidget extends StatelessWidget {
  final NoteBlock block;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onTypeChanged;

  const CalloutBlockWidget({
    super.key,
    required this.block,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final calloutType = (block.metadata['calloutType'] as String? ?? 'info').toLowerCase();

    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData icon;

    switch (calloutType) {
      case 'tip':
        bgColor = colors.successSubtle;
        borderColor = colors.accentEmerald;
        iconColor = colors.accentEmerald;
        icon = Icons.lightbulb_outline_rounded;
        break;
      case 'warning':
        bgColor = colors.warningSubtle;
        borderColor = colors.accentAmber;
        iconColor = colors.accentAmber;
        icon = Icons.warning_amber_rounded;
        break;
      case 'important':
        bgColor = colors.errorSubtle;
        borderColor = colors.accentRose;
        iconColor = colors.accentRose;
        icon = Icons.error_outline_rounded;
        break;
      case 'info':
      default:
        bgColor = colors.infoSubtle;
        borderColor = colors.accentPrimary;
        iconColor = colors.accentPrimary;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Change callout type',
            onSelected: onTypeChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'info', child: Text('Info (Blue)')),
              const PopupMenuItem(value: 'tip', child: Text('Tip (Emerald)')),
              const PopupMenuItem(value: 'warning', child: Text('Warning (Amber)')),
              const PopupMenuItem(value: 'important', child: Text('Important (Rose)')),
            ],
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 10),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              maxLines: null,
              style: TextStyle(
                fontSize: 14,
                color: colors.fgPrimary,
                height: 1.45,
              ),
              decoration: InputDecoration(
                hintText: 'Callout content...',
                hintStyle: TextStyle(color: colors.fgSecondary.withValues(alpha: 0.7)),
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
