import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../models/note_block_model.dart';

class ImageBlockWidget extends StatefulWidget {
  final NoteBlock block;
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<String> onCaptionChanged;

  const ImageBlockWidget({
    super.key,
    required this.block,
    required this.onUrlChanged,
    required this.onCaptionChanged,
  });

  @override
  State<ImageBlockWidget> createState() => _ImageBlockWidgetState();
}

class _ImageBlockWidgetState extends State<ImageBlockWidget> {
  late TextEditingController _urlController;
  late TextEditingController _captionController;
  bool _isEditingUrl = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.block.metadata['url'] as String? ?? '');
    _captionController = TextEditingController(text: widget.block.metadata['caption'] as String? ?? '');
    _isEditingUrl = _urlController.text.trim().isEmpty;
  }

  @override
  void didUpdateWidget(ImageBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentUrl = widget.block.metadata['url'] as String? ?? '';
    if (currentUrl != _urlController.text) {
      _urlController.text = currentUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = _urlController.text.trim();

    if (_isEditingUrl || url.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined, size: 18, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Text(
                  'Embed Image URL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.fgPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: TextStyle(fontSize: 13, color: colors.fgPrimary),
                    decoration: InputDecoration(
                      hintText: 'https://example.com/image.png',
                      hintStyle: TextStyle(fontSize: 13, color: colors.fgSecondary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: colors.bgCanvas,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final trimmed = _urlController.text.trim();
                    if (trimmed.isNotEmpty) {
                      widget.onUrlChanged(trimmed);
                      setState(() => _isEditingUrl = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.fgInverse,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Embed'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined, color: colors.accentRose, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image from URL',
                            style: TextStyle(color: colors.fgSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => setState(() => _isEditingUrl = true),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _captionController,
            onChanged: widget.onCaptionChanged,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.fgSecondary),
            decoration: InputDecoration(
              hintText: 'Add an optional image caption...',
              hintStyle: TextStyle(fontSize: 12, color: colors.fgSecondary.withValues(alpha: 0.6)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
