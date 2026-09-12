import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/learning_lab_model.dart';

class TranscriptGridPanel extends StatelessWidget {
  final List<TranscriptLine> lines;
  final int activeTimestampSeconds;
  final ValueChanged<TranscriptLine> onSelectLine;
  final ValueChanged<TranscriptLine> onAttachLineToChat;
  final VoidCallback onToggleToCanvas; // Toggle to Canvas view

  const TranscriptGridPanel({
    super.key,
    required this.lines,
    required this.activeTimestampSeconds,
    required this.onSelectLine,
    required this.onAttachLineToChat,
    required this.onToggleToCanvas,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          // Header Bar with Canvas Toggle Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgActivityBar,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
            ),
            child: Row(
              children: [
                Icon(Icons.subtitles_outlined, size: 16, color: colors.accentEmerald),
                const SizedBox(width: 8),
                Text(
                  'Transcript (Drag or @ to attach)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                ),
                const Spacer(),

                // Toggle to Canvas Button (replaces ✖)
                InkWell(
                  onTap: onToggleToCanvas,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.bgCanvas,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_4x4_rounded, size: 12, color: colors.accentPrimary),
                        const SizedBox(width: 4),
                        Text('Show Canvas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.accentPrimary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Clean Timestamp List Items (Drag & Drop + @ Button)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final isActive = (activeTimestampSeconds - line.timestampSeconds).abs() < 60;

                return Draggable<TranscriptLine>(
                  data: line,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.accentPrimary),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(line.formattedTime, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.accentEmerald)),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Text(line.text, style: TextStyle(fontSize: 12, color: colors.fgPrimary), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgCanvas,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? colors.borderActive : colors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => onSelectLine(line),
                          child: Text(
                            line.formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? colors.accentEmerald : colors.fgAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: InkWell(
                            onTap: () => onSelectLine(line),
                            child: Text(
                              line.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive ? colors.fgPrimary : colors.fgSecondary,
                              ),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: "Attach to AI Chat (@)",
                          child: InkWell(
                            onTap: () => onAttachLineToChat(line),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.bgSurface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colors.borderSubtle),
                              ),
                              child: Text('@', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.accentEmerald)),
                            ),
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
    );
  }
}
