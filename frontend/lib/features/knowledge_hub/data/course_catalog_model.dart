class CourseCatalogEntry {
  final String id;
  final String title;
  final String category;
  final String difficulty;
  final List<String> tags;
  final int estimatedHours;
  final String thumbnailUrl;

  CourseCatalogEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.tags,
    required this.estimatedHours,
    required this.thumbnailUrl,
  });
}
