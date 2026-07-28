import 'package:flutter/material.dart';

import 'youtube_player_widget.dart';

class VideoPlayerPanel extends StatefulWidget {
  final String videoTitle;
  final String videoId;
  final int currentTimestampSeconds;
  final ValueChanged<int> onTimestampChanged;
  final VoidCallback onAttachVideoToChat;

  const VideoPlayerPanel({
    super.key,
    required this.videoTitle,
    required this.videoId,
    required this.currentTimestampSeconds,
    required this.onTimestampChanged,
    required this.onAttachVideoToChat,
  });

  @override
  State<VideoPlayerPanel> createState() => _VideoPlayerPanelState();
}

class _VideoPlayerPanelState extends State<VideoPlayerPanel> {

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          YoutubePlayerWidget(videoId: widget.videoId),
        ],
      ),
    );
  }
}
