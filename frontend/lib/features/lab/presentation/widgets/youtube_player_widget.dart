import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../app/theme/app_theme.dart';

class YoutubePlayerWidget extends StatefulWidget {
  final String videoId;

  const YoutubePlayerWidget({super.key, required this.videoId});

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.videoId.isNotEmpty) {
      _initController(widget.videoId);
    }
  }

  void _initController(String id) {
    _controller?.close();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: id,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );
  }

  @override
  void didUpdateWidget(YoutubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      if (widget.videoId.isNotEmpty) {
        if (_controller == null) {
          _initController(widget.videoId);
        } else {
          _controller!.loadVideoById(videoId: widget.videoId);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoId.isEmpty || _controller == null) {
      return Container(
        color: AppColors.bgSurface,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.video_library_outlined, size: 48, color: AppColors.fgSecondary),
            SizedBox(height: 12),
            Text(
              'Loading video walkthrough...',
              style: TextStyle(color: AppColors.fgSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return YoutubePlayer(
      controller: _controller!,
      aspectRatio: 16 / 9,
    );
  }
}
