import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class GlobalScreenSwitcher extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectScreen;
  final Widget child;

  const GlobalScreenSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onSelectScreen,
    required this.child,
  });

  @override
  State<GlobalScreenSwitcher> createState() => _GlobalScreenSwitcherState();
}

class _GlobalScreenSwitcherState extends State<GlobalScreenSwitcher> {
  Offset? _position;
  bool _isMenuOpen = false;

  static const List<Map<String, String>> _screens = [
    {'id': '0', 'title': 'Screen 01: Command Center Dashboard'},
    {'id': '1', 'title': 'Screen 02: Micro-Interview (Assessment)'},
    {'id': '2', 'title': 'Screen 03: Learning Studio'},
    {'id': '6', 'title': 'Screen 04: AI Proctored Exam (Anti-Cheat)'},
    {'id': '3', 'title': 'Screen 05: Mastery Survey & Quizzes'},
    {'id': '4', 'title': 'Screen 06: Knowledge Hub'},
    {'id': '5', 'title': 'Screen 07: Profile & Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final colors = context.colors;

    // Default position at bottom-right if not initialized
    _position ??= Offset(screenSize.width - 70, screenSize.height - 110);

    return Stack(
      children: [
        // Main Screen Child Viewport
        widget.child,

        // Modal backdrop when menu is open
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isMenuOpen = false;
                });
              },
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),

        // Draggable Circle Button + Popup Menu Container
        Positioned(
          left: _position!.dx,
          top: _position!.dy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Screen Switcher Popup List (Wrapped in Material to satisfy InkWell)
              if (_isMenuOpen)
                Material(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 12,
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: 280,
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderActive, width: 1.5),
                      boxShadow: AppElevation.low,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: colors.borderSubtle)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.swap_calls_rounded, color: colors.accentEmerald, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Global Screen Switcher',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                              ),
                            ],
                          ),
                        ),

                        // Screen Options List
                        ..._screens.map((s) {
                          final index = int.parse(s['id']!);
                          final isSelected = widget.selectedIndex == index;
                          return InkWell(
                            onTap: () {
                              widget.onSelectScreen(index);
                              setState(() {
                                _isMenuOpen = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? colors.bgSecondary : Colors.transparent,
                                border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: isSelected ? colors.accentEmerald : colors.fgSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      s['title']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? colors.fgPrimary : colors.fgSecondary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_rounded, size: 14, color: colors.accentEmerald),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // Draggable Circle Button
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    double newX = _position!.dx + details.delta.dx;
                    double newY = _position!.dy + details.delta.dy;
                    // Clamp to screen bounds
                    newX = newX.clamp(10.0, screenSize.width - 60.0);
                    newY = newY.clamp(10.0, screenSize.height - 60.0);
                    _position = Offset(newX, newY);
                  });
                },
                onTap: () {
                  setState(() {
                    _isMenuOpen = !_isMenuOpen;
                  });
                },
                child: Material(
                  elevation: 8,
                  shape: const CircleBorder(),
                  color: colors.bgSurface,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isMenuOpen ? colors.accentEmerald : colors.bgSurface,
                      border: Border.all(
                        color: _isMenuOpen ? colors.accentEmerald : colors.borderActive,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isMenuOpen ? Icons.close_rounded : Icons.layers_rounded,
                      color: _isMenuOpen ? colors.fgInverse : colors.accentPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
