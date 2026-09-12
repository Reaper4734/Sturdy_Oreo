import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../models/note_block_model.dart';

class ChecklistBlockWidget extends StatelessWidget {
  final NoteBlock block;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onToggleChecked;

  const ChecklistBlockWidget({
    super.key,
    required this.block,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onToggleChecked,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isChecked = block.metadata['checked'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isChecked,
                activeColor: colors.accentEmerald,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: BorderSide(
                  color: isChecked ? colors.accentEmerald : colors.borderActive,
                  width: 1.5,
                ),
                onChanged: (val) {
                  onToggleChecked(val ?? false);
                },
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              maxLines: null,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isChecked ? colors.fgSecondary : colors.fgPrimary,
                decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: colors.fgSecondary,
              ),
              decoration: InputDecoration(
                hintText: 'To-do item...',
                hintStyle: TextStyle(color: colors.fgSecondary.withValues(alpha: 0.6)),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
