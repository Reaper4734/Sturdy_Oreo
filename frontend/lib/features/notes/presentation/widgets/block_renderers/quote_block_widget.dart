import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../models/note_block_model.dart';

class QuoteBlockWidget extends StatelessWidget {
  final NoteBlock block;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const QuoteBlockWidget({
    super.key,
    required this.block,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colors.accentPrimary,
            width: 3.5,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        maxLines: null,
        style: TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          height: 1.5,
          color: colors.fgPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Empty quote...',
          hintStyle: TextStyle(
            fontStyle: FontStyle.italic,
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
    );
  }
}
