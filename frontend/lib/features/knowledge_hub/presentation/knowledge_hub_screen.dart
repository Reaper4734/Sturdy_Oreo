import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../data/course_catalog_model.dart';
import '../data/http_course_catalog_repository.dart';
import 'widgets/course_card_widget.dart';
import 'course_preview_screen.dart';

class KnowledgeHubScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToWorkspace;

  const KnowledgeHubScreen({
    super.key,
    required this.onNavigateToWorkspace,
  });

  @override
  ConsumerState<KnowledgeHubScreen> createState() => _KnowledgeHubScreenState();
}

class _KnowledgeHubScreenState extends ConsumerState<KnowledgeHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CourseCatalogEntry> _searchResults = [];
  bool _isSearching = false;
  List<CourseCatalogEntry> _recommendations = [];
  List<CourseCatalogEntry> _allCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(httpCourseCatalogRepositoryProvider);
      final all = await repo.getAllCourses();
      final recs = await repo.getRecommendations(null);
      if (mounted) {
        setState(() {
          _allCourses = all;
          _recommendations = recs;
          _searchResults = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load catalog: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) async {
    setState(() => _isSearching = query.isNotEmpty);
    if (query.isEmpty) {
      setState(() => _searchResults = _allCourses);
      return;
    }
    
    try {
      final repo = ref.read(httpCourseCatalogRepositoryProvider);
      final results = await repo.search(query);
      if (mounted) {
        setState(() => _searchResults = results);
      }
    } catch (e) {
      debugPrint('Search failed: $e');
    }
  }

  void _navigateToPreview(CourseCatalogEntry course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoursePreviewScreen(
          course: course,
          onNavigateToWorkspace: widget.onNavigateToWorkspace,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Search
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Knowledge Hub',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colors.fgPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover and adopt AI-generated learning templates for your next workspace.',
                  style: TextStyle(fontSize: 16, color: colors.fgSecondary),
                ),
                const SizedBox(height: 24),
                // Search Bar
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(color: colors.fgPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search courses by topic, skill, or domain...',
                      hintStyle: TextStyle(color: colors.fgSecondary),
                      prefixIcon: Icon(Icons.search, color: colors.fgSecondary),
                      filled: true,
                      fillColor: colors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.borderActive),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content Scroll
          Expanded(
            child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                : _searchResults.isEmpty
                ? _buildEmptyState(context)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isSearching) ...[
                          Text(
                            'Recommended For You',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colors.fgPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildCourseGrid(_recommendations),
                          const SizedBox(height: 48),
                          Divider(color: colors.borderSubtle),
                          const SizedBox(height: 48),
                          Text(
                            'All Courses',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colors.fgPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          Text(
                            'Search Results for "${_searchController.text}"',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colors.fgPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        _buildCourseGrid(_searchResults),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseGrid(List<CourseCatalogEntry> courses) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.3,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCardWidget(
          course: course,
          onTap: () => _navigateToPreview(course),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: colors.borderSubtle),
          const SizedBox(height: 24),
          Text(
            'No matching course found.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.fgPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your own learning workspace from scratch.',
            style: TextStyle(fontSize: 16, color: colors.fgSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: widget.onNavigateToWorkspace,
            icon: const Icon(Icons.add),
            label: const Text('Create Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              foregroundColor: colors.fgInverse,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
