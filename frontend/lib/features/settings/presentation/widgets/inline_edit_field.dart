import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Inline-editable text field for settings.
/// Tap Edit → field becomes editable → Save/Cancel.
class InlineEditField extends StatefulWidget {
  final String label;
  final String value;
  final bool enabled;
  final ValueChanged<String> onSave;

  const InlineEditField({
    super.key,
    required this.label,
    required this.value,
    this.enabled = true,
    required this.onSave,
  });

  @override
  State<InlineEditField> createState() => _InlineEditFieldState();
}

class _InlineEditFieldState extends State<InlineEditField> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(InlineEditField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() async {
    widget.onSave(_controller.text);
    setState(() => _isEditing = false);
  }

  void _cancel() {
    _controller.text = widget.value;
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.fgSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: TextStyle(color: colors.fgPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.borderActive),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _save,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.accentEmerald,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: _cancel,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.fgSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value,
                    style: TextStyle(color: colors.fgPrimary, fontSize: 15),
                  ),
                ),
                if (widget.enabled)
                  TextButton(
                    onPressed: () => setState(() => _isEditing = true),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.fgSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
