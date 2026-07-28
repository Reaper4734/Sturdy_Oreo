import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../data/mock_course_catalog.dart';
import 'widgets/course_card_widget.dart';
import 'course_preview_screen.dart';

class KnowledgeHubScreen extends StatefulWidget {
  final VoidCallback onNavigateToWorkspace;

  const KnowledgeHubScreen({
    super.key,
    required this.onNavigateToWorkspace,
  });

  @override
  State<KnowledgeHubScreen> createState() => _KnowledgeHubScreenState();
}

class _KnowledgeHubScreenState extends State<KnowledgeHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CourseCatalogEntry> _searchResults = [];
  bool _isSearching = false;
  late final List<CourseCatalogEntry> _recommendations;
  late final List<CourseCatalogEntry> _allCourses;

  @override
  void initState() {
    super.initState();
    _allCourses = MockCourseCatalog.getAllCourses();
    _recommendations = MockCourseCatalog.getRecommendations(null); // Mock interview domain
    _searchResults = _allCourses;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _searchResults = MockCourseCatalog.search(query);
    });
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
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Search
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Knowledge Hub',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.fgPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Discover and adopt AI-generated learning templates for your next workspace.',
                  style: TextStyle(fontSize: 16, color: AppColors.fgSecondary),
                ),
                const SizedBox(height: 24),
                // Search Bar
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: AppColors.fgPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search courses by topic, skill, or domain...',
                      hintStyle: const TextStyle(color: AppColors.fgSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.fgSecondary),
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderActive),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content Scroll
          Expanded(
            child: _searchResults.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isSearching) ...[
                          const Text(
                            'Recommended For You',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.fgPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildCourseGrid(_recommendations),
                          const SizedBox(height: 48),
                          const Divider(color: AppColors.borderSubtle),
                          const SizedBox(height: 48),
                          const Text(
                            'All Courses',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.fgPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          Text(
                            'Search Results for "${_searchController.text}"',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.fgPrimary,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.borderSubtle),
          const SizedBox(height: 24),
          const Text(
            'No matching course found.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create your own learning workspace from scratch.',
            style: TextStyle(fontSize: 16, color: AppColors.fgSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: widget.onNavigateToWorkspace, // Assuming workspace creation leads there
            icon: const Icon(Icons.add),
            label: const Text('Create Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
