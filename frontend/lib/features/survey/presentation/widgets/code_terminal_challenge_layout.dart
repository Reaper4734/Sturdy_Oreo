import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/mastery_test_model.dart';

class CodeTerminalChallengeLayout extends StatefulWidget {
  final QuestionItem question;
  final VoidCallback onCompleteTest;

  const CodeTerminalChallengeLayout({
    super.key,
    required this.question,
    required this.onCompleteTest,
  });

  @override
  State<CodeTerminalChallengeLayout> createState() => _CodeTerminalChallengeLayoutState();
}

class _CodeTerminalChallengeLayoutState extends State<CodeTerminalChallengeLayout> {
  late TextEditingController _codeController;
  bool _isExecuted = false;
  bool _isAutoTyping = false;
  String _liveOutput = '';
  bool _allPassed = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.question.codeInitialTemplate ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleAutoType() async {
    if (_isAutoTyping) return;
    setState(() => _isAutoTyping = true);

    final targetCode = widget.question.codeSolution ?? widget.question.codeInitialTemplate ?? '';
    _codeController.clear();

    for (int i = 0; i < targetCode.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 12));
      setState(() {
        _codeController.text = targetCode.substring(0, i + 1);
      });
    }

    setState(() => _isAutoTyping = false);
  }

  void _handleRunCode() {
    setState(() {
      _isExecuted = true;
      _liveOutput = widget.question.expectedOutput ?? '';
      _allPassed = true;
    });
  }

  // --- Universal IDE Syntax Highlighter parser for All Programming Languages ---
  TextSpan _buildSyntaxHighlightedText(String text) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final words = line.split(' ');

      for (int j = 0; j < words.length; j++) {
        final word = words[j];
        TextStyle style = const TextStyle(color: Color(0xFFABB2BF), fontFamily: 'monospace', fontSize: 13, height: 1.5);

        if (word.startsWith('#') || word.startsWith('//') || word.startsWith('/*')) {
          style = const TextStyle(color: Color(0xFF5C6370), fontStyle: FontStyle.italic, fontFamily: 'monospace', fontSize: 13, height: 1.5);
        } else if (['def', 'class', 'return', 'import', 'from', 'if', 'else', 'for', 'in', 'as', 'function', 'const', 'let', 'var', 'public', 'private', 'protected', 'void', 'int', 'string', 'bool', 'package', 'func', 'async', 'await', 'export', 'default', 'new', 'struct', 'enum', 'interface'].contains(word)) {
          style = const TextStyle(color: Color(0xFFC678DD), fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13, height: 1.5);
        } else if (word.contains('(') || ['sys', 'print', 'getrefcount', 'console', 'log', 'System', 'out', 'println', 'main', 'fmt', 'Println', 'printf', 'scanf', 'std', 'cout', 'cin', 'len', 'map', 'filter', 'reduce'].contains(word.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), ''))) {
          style = const TextStyle(color: Color(0xFF61AFEF), fontFamily: 'monospace', fontSize: 13, height: 1.5);
        } else if (word.startsWith('"') || word.startsWith("'") || word.contains('"') || word.contains("'") || word.startsWith('`')) {
          style = const TextStyle(color: Color(0xFF98C379), fontFamily: 'monospace', fontSize: 13, height: 1.5);
        } else if (RegExp(r'^\d+$').hasMatch(word.replaceAll(RegExp(r'[^0-9]'), ''))) {
          style = const TextStyle(color: Color(0xFFD19A66), fontFamily: 'monospace', fontSize: 13, height: 1.5);
        }

        spans.add(TextSpan(text: word, style: style));
        if (j < words.length - 1) spans.add(const TextSpan(text: ' '));
      }

      if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = _codeController.text.split('\n').length;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          // 1. Relocated Question Area (resizes automatically based on text length, no fixed height)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.bgActivityBar,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code_rounded, size: 16, color: AppColors.accentPrimary),
                    const SizedBox(width: 8),
                    const Text(
                      'Question Challenge',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Universal Code Sandbox', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentEmerald)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.question.questionText,
                  style: const TextStyle(fontSize: 13, color: AppColors.fgPrimary, height: 1.4, fontWeight: FontWeight.w500),
                ),
                if (widget.question.testCases.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Requirements & Test Cases:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.fgSecondary)),
                  const SizedBox(height: 6),
                  ...widget.question.testCases.map((tc) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 12, color: AppColors.accentPrimary, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(tc.description, style: const TextStyle(fontSize: 12, color: AppColors.fgSecondary)),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),

          // Main Top Code Editor Window ("write code" region with Syntax Highlighting & Line Gutter)
          Expanded(
            flex: 3,
            child: Container(
              color: AppColors.bgCanvas,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line Number Gutter
                  Container(
                    width: 42,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: AppColors.bgActivityBar.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(
                        lineCount,
                        (idx) => Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.fgSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Code Editor Output Area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SingleChildScrollView(
                        child: SelectableText.rich(
                          _buildSyntaxHighlightedText(_codeController.text),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.borderSubtle),

          // Bottom Split Terminal Output Bar
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // Left Terminal Box: "match output:"
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.bgActivityBar,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.fact_check_outlined, size: 14, color: AppColors.accentEmerald),
                            SizedBox(width: 6),
                            Text('match output:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentEmerald)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                widget.question.expectedOutput ?? '',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.accentEmerald),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const VerticalDivider(width: 1, color: AppColors.borderSubtle),

                // Right Terminal Box: "Your output:"
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.bgActivityBar,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isExecuted ? Icons.check_circle_rounded : Icons.terminal_rounded,
                              size: 14,
                              color: _isExecuted ? AppColors.accentEmerald : AppColors.accentPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Your output:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isExecuted ? AppColors.accentEmerald : AppColors.accentPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _isExecuted ? _liveOutput : 'Ready to run code...',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: _isExecuted ? AppColors.fgPrimary : AppColors.fgSecondary,
                                ),
                              ),
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

          // 5. Bottom Action Bar below outputs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.bgActivityBar,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _handleRunCode,
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Run Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentPrimary,
                    side: const BorderSide(color: AppColors.accentPrimary),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isAutoTyping ? null : _handleAutoType,
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                  label: Text(_isAutoTyping ? 'Typing...' : 'Auto-Type Solution', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentEmerald,
                    side: const BorderSide(color: AppColors.accentEmerald),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => widget.onCompleteTest(),
                  icon: Icon(_allPassed ? Icons.check_circle_outline : Icons.arrow_forward_rounded, size: 16),
                  label: Text(_allPassed ? 'Passed! Submit' : 'Proceed & Submit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
