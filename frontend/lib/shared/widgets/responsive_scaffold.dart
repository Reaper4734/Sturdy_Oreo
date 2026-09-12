import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../providers/workspace_providers.dart';
import 'global_screen_switcher.dart';
import 'workspace_panel.dart';

class ResponsiveScaffold extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const ResponsiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlobalScreenSwitcher(
      selectedIndex: selectedIndex,
      onSelectScreen: onDestinationSelected,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 768) {
            return _buildDesktopWorkbench(context, ref);
          } else {
            return _buildMobileApp(context, ref);
          }
        },
      ),
    );
  }

  // Desktop / Web Layout: Hallmark Modern-Minimal Activity Rail (Monochrome, No Purple)
  Widget _buildDesktopWorkbench(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(workspacePanelOpenProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Row(
        children: [
          // Left Vertical Activity Bar (Icon Rail Only)
          Container(
            width: 56,
            decoration: BoxDecoration(
              color: colors.bgActivityBar,
              border: Border(right: BorderSide(color: colors.borderSubtle, width: 0.8)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Brand Icon
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Icon(Icons.auto_awesome, color: colors.accentPrimary, size: 18),
                ),
                const SizedBox(height: 16),

                // NEW: Learning Spaces Explorer Icon (Top of Rail)
                _buildWorkspaceRailButton(context, ref, isOpen),
                const SizedBox(height: 8),
                Divider(height: 1, color: colors.borderSubtle, indent: 8, endIndent: 8),
                const SizedBox(height: 8),

                // Nav Icons with Hover Tooltips (All 5 Existing Tabs Preserved Exactly)
                _buildRailIconButton(0, Icons.dashboard_outlined, 'Dashboard'),
                _buildRailIconButton(1, Icons.chat_bubble_outline, 'Interview'),
                _buildRailIconButton(2, Icons.radar_outlined, 'Studio'),
                _buildRailIconButton(3, Icons.assignment_turned_in_outlined, 'Quizzes'),
                _buildRailIconButton(4, Icons.explore_outlined, 'Hub'),

                const Spacer(),

                // NEW: Auto-save status indicator
                _buildAutoSaveIndicator(context, ref),
                const SizedBox(height: 12),

                // Pinned Profile Section at Bottom Left
                Tooltip(
                  message: 'User Profile & Settings (Priyaj Gawade)',
                  preferBelow: false,
                  verticalOffset: 20,
                  child: InkWell(
                    onTap: () => onDestinationSelected(5),
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 20.0),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xFFD97706),
                        child: Text('PG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Viewport Area with Slide-Out Panel Overlay
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: colors.bgCanvas,
                    child: child,
                  ),
                ),
                if (isOpen)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: WorkspacePanel(
                      onNewWorkspaceClicked: () {
                        onDestinationSelected(1); // Navigate to Screen 01: Micro-Interview
                      },
                      onWorkspaceSelected: () {
                        onDestinationSelected(2); // Navigate to Learning Studio (PersonaRevealScreen)
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Smartphone Layout: Top Bar + Bottom Navigation
  Widget _buildMobileApp(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(workspacePanelOpenProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgActivityBar,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text('Oreo AI Tutor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.workspaces_outlined,
              color: isOpen ? colors.accentPrimary : colors.fgSecondary,
              size: 20,
            ),
            tooltip: 'Learning Spaces',
            onPressed: () {
              ref.read(workspacePanelOpenProvider.notifier).state = !isOpen;
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 13,
              backgroundColor: Color(0xFFD97706),
              child: Text('PG', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: child),
          if (isOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: WorkspacePanel(
                onNewWorkspaceClicked: () {
                  onDestinationSelected(1);
                },
                onWorkspaceSelected: () {
                  onDestinationSelected(2);
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onDestinationSelected,
        backgroundColor: colors.bgActivityBar,
        selectedItemColor: colors.accentPrimary,
        unselectedItemColor: colors.fgSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Center'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.radar_outlined), label: 'Studio'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Quiz'),
        ],
      ),
    );
  }

  Widget _buildWorkspaceRailButton(BuildContext context, WidgetRef ref, bool isOpen) {
    final colors = context.colors;
    return Tooltip(
      message: 'Learning Spaces Explorer',
      preferBelow: false,
      verticalOffset: 20,
      child: InkWell(
        onTap: () {
          ref.read(workspacePanelOpenProvider.notifier).state = !isOpen;
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isOpen ? colors.accentPrimary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isOpen ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.4)) : null,
          ),
          child: Icon(
            Icons.workspaces_outlined,
            color: isOpen ? colors.accentPrimary : colors.fgSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoSaveIndicator(BuildContext context, WidgetRef ref) {
    final status = ref.watch(autoSaveStatusProvider);
    final isSaving = status == 'Saving...';
    final colors = context.colors;
    return Tooltip(
      message: 'Ponytail In-Memory Auto-Save: $status',
      preferBelow: false,
      verticalOffset: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isSaving ? colors.accentAmber : colors.accentEmerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isSaving ? '...' : '✓',
            style: TextStyle(fontSize: 10, color: colors.fgSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRailIconButton(int index, IconData icon, String tooltip) {
    return _RailNavButton(
      index: index,
      selectedIndex: selectedIndex,
      icon: icon,
      tooltip: tooltip,
      onSelect: onDestinationSelected,
    );
  }
}

class _RailNavButton extends StatefulWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final String tooltip;
  final ValueChanged<int> onSelect;

  const _RailNavButton({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.tooltip,
    required this.onSelect,
  });

  @override
  State<_RailNavButton> createState() => _RailNavButtonState();
}

class _RailNavButtonState extends State<_RailNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.selectedIndex == widget.index;
    final colors = context.colors;

    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      verticalOffset: 20,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => widget.onSelect(widget.index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.accentPrimary.withValues(alpha: 0.15)
                  : (_isHovered ? colors.bgElevated : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.4))
                  : null,
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    left: 0,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accentPrimary.withValues(alpha: 0.5),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                  ),
                Center(
                  child: Icon(
                    widget.icon,
                    color: isSelected
                        ? colors.accentPrimary
                        : (_isHovered ? colors.fgPrimary : colors.fgSecondary),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
