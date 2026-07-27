import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class VideoPlayerPanel extends StatefulWidget {
  final String videoTitle;
  final int currentTimestampSeconds;
  final ValueChanged<int> onTimestampChanged;
  final VoidCallback onAttachVideoToChat;

  const VideoPlayerPanel({
    super.key,
    required this.videoTitle,
    required this.currentTimestampSeconds,
    required this.onTimestampChanged,
    required this.onAttachVideoToChat,
  });

  @override
  State<VideoPlayerPanel> createState() => _VideoPlayerPanelState();
}

class _VideoPlayerPanelState extends State<VideoPlayerPanel> {
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  bool _showControls = true;

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _cyclePlaybackSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.25;
      } else if (_playbackSpeed == 1.25) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.currentTimestampSeconds / 765.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _showControls = true),
        onExit: (_) => setState(() => _showControls = false),
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Content Area (full bleed)
              GestureDetector(
                onTap: () => setState(() => _isPlaying = !_isPlaying),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isPlaying ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                        size: 56,
                        color: Colors.white.withValues(alpha: _showControls ? 0.9 : 0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'CPython Heap Memory Pointer Allocation',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top-left: Subtle Video Title Badge (semi-transparent)
              Positioned(
                top: 10,
                left: 10,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    widget.videoTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),

              // Bottom Transparent Overlay Controls (YouTube-style)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scrubber
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            activeTrackColor: AppColors.accentPrimary,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                            thumbColor: AppColors.accentPrimary,
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (val) {
                              widget.onTimestampChanged((val * 765).toInt());
                            },
                          ),
                        ),

                        // Control Buttons Row
                        Row(
                          children: [
                            // Play/Pause
                            IconButton(
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32),
                              icon: Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => setState(() => _isPlaying = !_isPlaying),
                            ),

                            // Timestamp
                            Text(
                              '${_formatTime(widget.currentTimestampSeconds)} / 12:45',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(width: 8),

                            // Chapter Label
                            Text(
                              'Intro',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white54),

                            const Spacer(),

                            // Volume
                            IconButton(
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28),
                              icon: Icon(Icons.volume_up_rounded, color: Colors.white.withValues(alpha: 0.8)),
                              onPressed: () {},
                            ),

                            // Speed
                            InkWell(
                              onTap: _cyclePlaybackSpeed,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Text(
                                  '${_playbackSpeed}x',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // @ Attach
                            IconButton(
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28),
                              tooltip: 'Attach Video to AI Chat (@)',
                              icon: Text('@', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentPrimary)),
                              onPressed: widget.onAttachVideoToChat,
                            ),

                            // Settings
                            IconButton(
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28),
                              icon: Icon(Icons.settings_outlined, color: Colors.white.withValues(alpha: 0.8)),
                              onPressed: () {},
                            ),

                            // Fullscreen
                            IconButton(
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28),
                              icon: Icon(Icons.fullscreen_rounded, color: Colors.white.withValues(alpha: 0.8)),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
