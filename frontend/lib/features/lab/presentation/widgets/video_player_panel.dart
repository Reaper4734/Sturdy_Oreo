import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
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
  int _activeTab = 0; // 0: Chapters, 1: High-Yield AI Summary
  bool _showCompanion = false; // Collapsible companion drawer
  int? _seekTargetSeconds;

  List<Map<String, dynamic>> _getDynamicChapters() {
    final title = widget.videoTitle.toLowerCase();

    if (title.contains('k-means') || title.contains('kmeans') || title.contains('clustering')) {
      return [
        {'time': '00:00', 'seconds': 0, 'title': 'Overview of Clustering & Distance Metrics'},
        {'time': '02:15', 'seconds': 135, 'title': 'Centroid Initialization & Formula'},
        {'time': '05:40', 'seconds': 340, 'title': 'Step-by-Step Numerical Example Calculation'},
        {'time': '09:10', 'seconds': 550, 'title': 'Iterative Recalculation & Reassignment'},
        {'time': '12:30', 'seconds': 750, 'title': 'Convergence Condition & Elbow Curve (WCSS)'},
      ];
    } else if (title.contains('numpy') || title.contains('array') || title.contains('python')) {
      return [
        {'time': '00:00', 'seconds': 0, 'title': 'NumPy Ndarray Fundamentals & Memory Layout'},
        {'time': '03:20', 'seconds': 200, 'title': 'Array Reshaping, Slicing & Indexing'},
        {'time': '07:15', 'seconds': 435, 'title': 'Broadcasting Rules & Mathematical Operations'},
        {'time': '11:45', 'seconds': 705, 'title': 'Boolean Masking & Fast Aggregations'},
      ];
    } else if (title.contains('imputation') || title.contains('missing') || title.contains('pandas')) {
      return [
        {'time': '00:00', 'seconds': 0, 'title': 'Missing Data Classifications: MCAR, MAR, MNAR'},
        {'time': '02:30', 'seconds': 150, 'title': 'Mean, Median & Mode Statistical Imputation'},
        {'time': '06:10', 'seconds': 370, 'title': 'KNN and Multivariate Imputation (MICE)'},
        {'time': '09:45', 'seconds': 585, 'title': 'Evaluating Imputation vs Machine Learning Metrics'},
      ];
    } else {
      return [
        {'time': '00:00', 'seconds': 0, 'title': '${widget.videoTitle}: Core Fundamentals'},
        {'time': '03:15', 'seconds': 195, 'title': 'Algorithmic Walkthrough & Trace'},
        {'time': '06:45', 'seconds': 405, 'title': 'Edge Cases, Pitfalls & Optimization'},
        {'time': '10:20', 'seconds': 620, 'title': 'Verification & Production Deployment'},
      ];
    }
  }

  void _jumpToChapter(int seconds) {
    setState(() {
      _seekTargetSeconds = seconds;
    });
    widget.onTimestampChanged(seconds);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seeking video to ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}...'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        Widget videoContent = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              YoutubePlayerWidget(
                videoId: widget.videoId,
                seekToSeconds: _seekTargetSeconds,
              ),
              if (!_showCompanion)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.bgSurface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildOverlayAction(
                          icon: Icons.bookmarks_outlined,
                          label: 'Chapters',
                          onTap: () => setState(() {
                            _activeTab = 0;
                            _showCompanion = true;
                          }),
                          colors: colors,
                        ),
                        const SizedBox(width: 4),
                        _buildOverlayAction(
                          icon: Icons.auto_awesome_outlined,
                          label: '2-Min AI Summary',
                          onTap: () => setState(() {
                            _activeTab = 1;
                            _showCompanion = true;
                          }),
                          colors: colors,
                        ),
                        const SizedBox(width: 4),
                        _buildOverlayAction(
                          icon: Icons.forum_outlined,
                          label: 'Ask Tutor',
                          onTap: widget.onAttachVideoToChat,
                          colors: colors,
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );

        if (!_showCompanion) {
          return Container(
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle, width: 0.8),
            ),
            child: videoContent,
          );
        }

        // When companion drawer is open
        Widget companionPanel = Container(
          width: isWide ? 330 : double.infinity,
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: isWide
                ? const BorderRadius.horizontal(right: Radius.circular(12))
                : BorderRadius.circular(12),
            border: isWide
                ? Border(left: BorderSide(color: colors.borderSubtle, width: 0.8))
                : Border.all(color: colors.borderSubtle, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Companion Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: isWide
                      ? const BorderRadius.only(topRight: Radius.circular(12))
                      : const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Chapters', Icons.bookmarks_outlined, colors),
                    const SizedBox(width: 6),
                    _buildTabButton(1, '2-Min Summary', Icons.auto_awesome_outlined, colors),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Ask AI Tutor about video',
                      icon: Icon(Icons.forum_outlined, size: 15, color: colors.accentCyan),
                      onPressed: widget.onAttachVideoToChat,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Close companion panel',
                      icon: Icon(Icons.close, size: 16, color: colors.fgSecondary),
                      onPressed: () => setState(() => _showCompanion = false),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              // Companion Tab Body
              Expanded(
                child: _activeTab == 0
                    ? _buildChaptersList(colors)
                    : _buildExecutiveSummary(colors),
              ),
            ],
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle, width: 0.8),
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: videoContent),
                    companionPanel,
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    videoContent,
                    Positioned.fill(child: companionPanel),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildOverlayAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColorsExtension colors,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: highlight
              ? colors.accentCyan.withValues(alpha: 0.2)
              : colors.bgElevated.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: highlight
                ? colors.accentCyan.withValues(alpha: 0.5)
                : colors.borderSubtle,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: highlight ? colors.accentCyan : colors.fgPrimary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                color: highlight ? colors.accentCyan : colors.fgPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, AppColorsExtension colors) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: colors.accentCyan.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? colors.accentCyan : colors.fgSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colors.accentCyan : colors.fgSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChaptersList(AppColorsExtension colors) {
    final chapters = _getDynamicChapters();

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: chapters.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: colors.borderSubtle.withValues(alpha: 0.5)),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final seconds = chapter['seconds'] as int;
        final isActive = _seekTargetSeconds == seconds ||
            (_seekTargetSeconds == null && index == 0);

        return InkWell(
          onTap: () => _jumpToChapter(seconds),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? colors.accentCyan.withValues(alpha: 0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive ? colors.accentCyan : colors.borderSubtle,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    chapter['time'],
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: isActive ? colors.accentCyan : colors.fgSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    chapter['title'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? colors.accentCyan : colors.fgPrimary,
                    ),
                  ),
                ),
                Icon(
                  isActive ? Icons.play_arrow_rounded : Icons.play_circle_outline,
                  size: 16,
                  color: isActive ? colors.accentCyan : colors.fgSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExecutiveSummary(AppColorsExtension colors) {
    final title = widget.videoTitle.toLowerCase();
    String takeaways;
    String codeHook;

    if (title.contains('k-means') || title.contains('kmeans') || title.contains('clustering')) {
      takeaways =
          '• Centroid Assignment: Partitions n observations into k clusters where each point belongs to the cluster with the nearest mean.\n'
          r'• Cost Function: Minimizes Within-Cluster Sum of Squares (WCSS / Inertia): $\sum ||x_i - \mu_k||^2.' '\n'
          '• Optimal K: Determined by the Elbow Curve method and Silhouette Coefficient analysis.';
      codeHook =
          'from sklearn.cluster import KMeans\n'
          'kmeans = KMeans(n_clusters=3, init="k-means++", random_state=42)\n'
          'labels = kmeans.fit_predict(X_scaled)';
    } else if (title.contains('numpy') || title.contains('array')) {
      takeaways =
          '• Contiguous Memory: Ndarrays provide C-speed execution by avoiding Python pointer dereferencing.\n'
          '• Broadcasting: Smaller arrays are implicitly expanded to match larger shapes without copying data.\n'
          '• Vectorization: Replaces Python for-loops with SIMD vector instructions for 50x-100x speedup.';
      codeHook =
          'import numpy as np\n'
          '# Fast vectorized normalization without loops\n'
          'norm_X = (X - np.mean(X, axis=0)) / np.std(X, axis=0)';
    } else {
      takeaways =
          '• Core Concept: ${widget.videoTitle} foundational mechanics and architecture patterns.\n'
          '• Performance: Eliminates bottlenecks by adopting efficient data structures and non-blocking idioms.\n'
          '• Verification: Evaluates algorithmic correctness with unit tests and production constraints.';
      codeHook =
          '// Implementation Pattern\n'
          'final result = await executePipeline(context: "${widget.videoTitle}");';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 14, color: colors.accentAmber),
              const SizedBox(width: 6),
              Text(
                'HIGH-YIELD TAKEAWAYS (NO-FLUFF SUMMARY)',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                  color: colors.accentAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            takeaways,
            style: TextStyle(fontSize: 11, height: 1.4, color: colors.fgPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.borderSubtle, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '// Key Implementation Hook',
                  style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: colors.fgTertiary),
                ),
                const SizedBox(height: 4),
                Text(
                  codeHook,
                  style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: colors.accentCyan),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
