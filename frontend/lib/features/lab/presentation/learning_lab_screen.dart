import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class LearningLabScreen extends StatefulWidget {
  final String activeNodeTitle;
  final VoidCallback onUndoBackToMindMap;

  const LearningLabScreen({
    super.key,
    required this.activeNodeTitle,
    required this.onUndoBackToMindMap,
  });

  @override
  State<LearningLabScreen> createState() => _LearningLabScreenState();
}

class _LearningLabScreenState extends State<LearningLabScreen> {
  final TextEditingController _codeController = TextEditingController(
    text: '''# Python OOPs & Memory Pointer Simulation
class PyObject:
    def __init__(self, ref_count=1, type_name="int"):
        self.ref_count = ref_count
        self.type_name = type_name

# Allocating heap object
obj = PyObject(ref_count=1, type_name="List[int]")
print(f"Allocated {obj.type_name} with Ref Count: {obj.ref_count}")
''',
  );

  String _terminalOutput = '>>> Executing Python Memory Simulation...\n[Success] Heap Memory Allocated at 0x7FFF9A20\nRef Count: 1\n';
  bool _isRunningCode = false;

  void _runCode() {
    setState(() {
      _isRunningCode = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isRunningCode = false;
          _terminalOutput += '>>> Ran successfully: Object reference clean.\n';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        children: [
          // Top Header Bar with Undo / Back Button
          _buildLabHeader(context),

          // Main Workspace (Dual Pane Layout: Left Video/Canvas, Right Compiler/Terminal)
          Expanded(
            child: Row(
              children: [
                // Left Column: Video Player & AI Canvas Simulation
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: AppColors.borderSubtle)),
                    ),
                    child: Column(
                      children: [
                        // Video Player Card Simulation
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_circle_fill_rounded, size: 56, color: AppColors.accentPrimary),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Video Lecture: ${widget.activeNodeTitle}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Interactive Memory Pointer Walkthrough (12:45)', style: TextStyle(fontSize: 12, color: AppColors.fgSecondary)),
                                  ],
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 16,
                                  right: 16,
                                  child: Row(
                                    children: const [
                                      Icon(Icons.play_arrow_rounded, color: AppColors.fgPrimary, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: 0.45,
                                          backgroundColor: AppColors.bgElevated,
                                          color: AppColors.accentEmerald,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('05:42 / 12:45', style: TextStyle(fontSize: 11, color: AppColors.fgSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Interactive AI Canvas Area
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.draw_outlined, size: 18, color: AppColors.fgAccent),
                                    SizedBox(width: 8),
                                    Text('Interactive AI Canvas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
                                    Spacer(),
                                    Icon(Icons.gesture_rounded, size: 16, color: AppColors.fgSecondary),
                                  ],
                                ),
                                const Divider(color: AppColors.borderSubtle, height: 20),
                                const Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.account_tree_outlined, size: 40, color: AppColors.borderActive),
                                        SizedBox(width: 12),
                                        Text(
                                          'Memory Allocation Flowchart & Heap Pointers Diagram',
                                          style: TextStyle(fontSize: 13, color: AppColors.fgSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Column: Code Compiler & Terminal Panel
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.bgCanvas,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Code Editor Header
                        Row(
                          children: [
                            const Icon(Icons.code_rounded, size: 18, color: AppColors.accentEmerald),
                            const SizedBox(width: 8),
                            const Text('Python 3.11 Sandbox', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
                            const Spacer(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentEmerald,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: _isRunningCode
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.black),
                              label: const Text('Run Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: _isRunningCode ? null : _runCode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Code Editor Textarea
                        Expanded(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: TextField(
                              controller: _codeController,
                              maxLines: null,
                              expands: true,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Terminal Output Container
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.terminal_rounded, size: 14, color: AppColors.fgSecondary),
                                    SizedBox(width: 6),
                                    Text('Terminal Output', style: TextStyle(fontSize: 11, color: AppColors.fgSecondary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Divider(color: AppColors.borderSubtle, height: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _terminalOutput,
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11, color: AppColors.accentEmerald),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Top Header with Undo / Back Button
  Widget _buildLabHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.bgActivityBar,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8)),
      ),
      child: Row(
        children: [
          // UNDO / BACK TO MIND MAP BUTTON
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderActive),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.undo_rounded, size: 16, color: AppColors.accentPrimary),
            label: const Text('↩ Back to Mind Map Node Selection', style: TextStyle(fontSize: 12, color: AppColors.accentPrimary, fontWeight: FontWeight.bold)),
            onPressed: widget.onUndoBackToMindMap,
          ),
          const SizedBox(width: 16),
          Text(
            'Screen 04: Learning Lab Workspace',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Active Node: ${widget.activeNodeTitle}', style: const TextStyle(fontSize: 11, color: AppColors.accentEmerald, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
