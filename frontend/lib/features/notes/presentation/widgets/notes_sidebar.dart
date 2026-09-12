import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../models/note_page_model.dart';
import '../../providers/notes_provider.dart';

class NotesSidebar extends ConsumerStatefulWidget {
  final VoidCallback? onPageSelected;

  const NotesSidebar({super.key, this.onPageSelected});

  @override
  ConsumerState<NotesSidebar> createState() => _NotesSidebarState();
}

class _NotesSidebarState extends ConsumerState<NotesSidebar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRenameDialog(BuildContext context, NotePage page) {
    final controller = TextEditingController(text: page.title);
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgSurface,
        title: Text('Rename Page', style: TextStyle(color: colors.fgPrimary, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.fgPrimary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.bgCanvas,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.fgSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                ref.read(notesNotifierProvider.notifier).updatePageTitle(newTitle);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              foregroundColor: colors.fgInverse,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, NotePage page) {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgSurface,
        title: Text('Delete "${page.title}"?', style: TextStyle(color: colors.fgPrimary, fontSize: 16)),
        content: Text(
          'This will delete the page and all sub-pages inside it. This action cannot be undone.',
          style: TextStyle(color: colors.fgSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.fgSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notesNotifierProvider.notifier).deletePage(page.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentRose,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notesState = ref.watch(notesNotifierProvider);
    final pages = notesState.pages;
    final searchQuery = notesState.searchQuery.toLowerCase();

    // Filter pages
    final filteredPages = searchQuery.isEmpty
        ? pages
        : pages.where((p) => p.title.toLowerCase().contains(searchQuery)).toList();

    // Group into root and child pages
    final rootPages = searchQuery.isEmpty
        ? filteredPages.where((p) => p.parentPageId == null || p.parentPageId!.isEmpty).toList()
        : filteredPages;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colors.bgActivityBar,
        border: Border(right: BorderSide(color: colors.borderSubtle, width: 0.8)),
      ),
      child: Column(
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 18, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.fgPrimary,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'New Page',
                  child: InkWell(
                    onTap: () {
                      ref.read(notesNotifierProvider.notifier).createPage(title: 'Untitled');
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.add_rounded, size: 18, color: colors.accentPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: colors.bgCanvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(Icons.search_rounded, size: 16, color: colors.fgSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(notesNotifierProvider.notifier).setSearchQuery(val);
                      },
                      style: TextStyle(fontSize: 12, color: colors.fgPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search notes...',
                        hintStyle: TextStyle(fontSize: 12, color: colors.fgSecondary.withValues(alpha: 0.6)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        ref.read(notesNotifierProvider.notifier).setSearchQuery('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(Icons.close_rounded, size: 14, color: colors.fgSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),
          Divider(height: 1, color: colors.borderSubtle),

          // Pages Tree View
          Expanded(
            child: notesState.isLoading && pages.isEmpty
                ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                : pages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 36, color: colors.fgSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'No pages yet',
                              style: TextStyle(fontSize: 12, color: colors.fgSecondary),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                ref.read(notesNotifierProvider.notifier).createPage(title: 'Getting Started');
                              },
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Create Page', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        itemCount: rootPages.length,
                        itemBuilder: (context, index) {
                          final page = rootPages[index];
                          return _buildPageTreeNode(context, page, pages, 0);
                        },
                      ),
          ),

          // Bottom New Page Quick Action
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgActivityBar,
              border: Border(top: BorderSide(color: colors.borderSubtle, width: 0.8)),
            ),
            child: InkWell(
              onTap: () {
                ref.read(notesNotifierProvider.notifier).createPage(title: 'Untitled');
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.bgCanvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: colors.accentPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'New Page',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTreeNode(
    BuildContext context,
    NotePage page,
    List<NotePage> allPages,
    int depth,
  ) {
    final colors = context.colors;
    final notesState = ref.watch(notesNotifierProvider);
    final isSelected = notesState.selectedPageId == page.id;
    final isCollapsed = notesState.collapsedParentIds.contains(page.id);

    final childPages = allPages.where((p) => p.parentPageId == page.id).toList();
    final hasChildren = childPages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            ref.read(notesNotifierProvider.notifier).selectPage(page.id);
            if (widget.onPageSelected != null) {
              widget.onPageSelected!();
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: EdgeInsets.only(
              left: 6.0 + (depth * 14.0),
              right: 6,
              top: 5,
              bottom: 5,
            ),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Expand / collapse carat
                if (hasChildren)
                  InkWell(
                    onTap: () {
                      ref.read(notesNotifierProvider.notifier).toggleParentCollapse(page.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Icon(
                        isCollapsed ? Icons.chevron_right_rounded : Icons.expand_more_rounded,
                        size: 16,
                        color: colors.fgSecondary,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 16),

                // Material Document / Folder Icon
                Icon(
                  hasChildren ? Icons.folder_outlined : Icons.description_outlined,
                  size: 15,
                  color: isSelected ? colors.accentPrimary : colors.fgSecondary,
                ),
                const SizedBox(width: 8),

                // Title
                Expanded(
                  child: Text(
                    page.title.isEmpty ? 'Untitled' : page.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colors.fgPrimary : colors.fgSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 3-dots Context Menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, size: 16, color: colors.fgSecondary),
                  padding: EdgeInsets.zero,
                  color: colors.bgSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colors.borderSubtle),
                  ),
                  onSelected: (val) {
                    if (val == 'add_subpage') {
                      ref.read(notesNotifierProvider.notifier).createPage(
                            title: 'Untitled Sub-page',
                            parentPageId: page.id,
                          );
                    } else if (val == 'rename') {
                      _showRenameDialog(context, page);
                    } else if (val == 'delete') {
                      _showDeleteDialog(context, page);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'add_subpage',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, size: 16, color: colors.fgSecondary),
                          const SizedBox(width: 8),
                          const Text('Add sub-page', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: colors.fgSecondary),
                          const SizedBox(width: 8),
                          const Text('Rename', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: colors.accentRose),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(fontSize: 12, color: colors.accentRose)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Render children if expanded
        if (hasChildren && !isCollapsed)
          ...childPages.map((cp) => _buildPageTreeNode(context, cp, allPages, depth + 1)),
      ],
    );
  }
}
