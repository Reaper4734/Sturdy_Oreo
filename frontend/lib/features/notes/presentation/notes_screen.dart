import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/notes_provider.dart';
import 'widgets/notes_editor.dart';
import 'widgets/notes_sidebar.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notesState = ref.watch(notesNotifierProvider);
    final activePage = notesState.activePage;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            // Mobile layout: Drawer / Sliding Sidebar + Editor
            return Row(
              children: [
                Expanded(
                  child: activePage != null
                      ? NotesEditor(page: activePage)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_rounded, size: 48, color: colors.accentPrimary),
                              const SizedBox(height: 16),
                              Text(
                                'Select a note page to begin',
                                style: TextStyle(fontSize: 16, color: colors.fgPrimary, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref.read(notesNotifierProvider.notifier).createPage(title: 'Getting Started');
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Create Page'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.accentPrimary,
                                  foregroundColor: colors.fgInverse,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          }

          // Desktop Layout: Sidebar + Editor Pane
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Notes Workspace Sidebar
              const NotesSidebar(),

              // Right Block-based Editor Viewport
              Expanded(
                child: notesState.isLoading && activePage == null
                    ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                    : activePage != null
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: NotesEditor(page: activePage),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book_outlined, size: 48, color: colors.fgSecondary.withValues(alpha: 0.6)),
                                const SizedBox(height: 16),
                                Text(
                                  'Select a note page or create a new one',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.fgPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    ref.read(notesNotifierProvider.notifier).createPage(title: 'Getting Started');
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Create Page'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.accentPrimary,
                                    foregroundColor: colors.fgInverse,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
