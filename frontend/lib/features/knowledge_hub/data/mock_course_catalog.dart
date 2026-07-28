

class CourseCatalogEntry {
  final String id;
  final String title;
  final List<String> keywords;
  final int durationHours;
  final String domain;
  final String knowledgeGraphWorkspaceId; // Maps to MockKnowledgeGraphData key for Mind Map + Roadmap

  CourseCatalogEntry({
    required this.id,
    required this.title,
    required this.keywords,
    required this.durationHours,
    required this.domain,
    required this.knowledgeGraphWorkspaceId,
  });
}

class MockCourseCatalog {
  static final List<CourseCatalogEntry> _courses = [
    CourseCatalogEntry(
      id: 'course_1',
      title: 'Python Backend Engineering',
      keywords: ['Python', 'FastAPI', 'REST APIs', 'Docker'],
      durationHours: 42,
      domain: 'Backend',
      knowledgeGraphWorkspaceId: 'python_backend',
    ),
    CourseCatalogEntry(
      id: 'course_2',
      title: 'React Frontend Development',
      keywords: ['React', 'Hooks', 'State Management', 'Vite'],
      durationHours: 35,
      domain: 'Frontend',
      knowledgeGraphWorkspaceId: 'react_frontend',
    ),
    CourseCatalogEntry(
      id: 'course_3',
      title: 'Java Collections & Streams',
      keywords: ['Java', 'Data Structures', 'Streams API', 'Lambdas'],
      durationHours: 20,
      domain: 'Backend',
      knowledgeGraphWorkspaceId: 'java_collections',
    ),
    CourseCatalogEntry(
      id: 'course_4',
      title: 'Spring Boot Microservices',
      keywords: ['Spring Boot', 'Microservices', 'Kafka', 'PostgreSQL'],
      durationHours: 50,
      domain: 'Backend',
      knowledgeGraphWorkspaceId: 'python_backend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_5',
      title: 'AI Fundamentals',
      keywords: ['AI', 'Neural Networks', 'PyTorch', 'Concepts'],
      durationHours: 30,
      domain: 'AI/ML',
      knowledgeGraphWorkspaceId: 'react_frontend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_6',
      title: 'Machine Learning with Python',
      keywords: ['Machine Learning', 'Scikit-Learn', 'Pandas', 'Data Science'],
      durationHours: 45,
      domain: 'AI/ML',
      knowledgeGraphWorkspaceId: 'python_backend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_7',
      title: 'Data Structures & Algorithms',
      keywords: ['DSA', 'Algorithms', 'Big O', 'Problem Solving'],
      durationHours: 60,
      domain: 'Computer Science',
      knowledgeGraphWorkspaceId: 'java_collections', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_8',
      title: 'Flutter Development',
      keywords: ['Flutter', 'Dart', 'Mobile Apps', 'UI Design'],
      durationHours: 40,
      domain: 'Frontend',
      knowledgeGraphWorkspaceId: 'react_frontend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_9',
      title: 'Cyber Security Foundations',
      keywords: ['Security', 'Networking', 'Cryptography', 'OWASP'],
      durationHours: 25,
      domain: 'Security',
      knowledgeGraphWorkspaceId: 'python_backend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_10',
      title: 'DevOps Essentials',
      keywords: ['DevOps', 'CI/CD', 'GitLab', 'Terraform'],
      durationHours: 32,
      domain: 'DevOps',
      knowledgeGraphWorkspaceId: 'java_collections', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_11',
      title: 'Docker & Kubernetes',
      keywords: ['Docker', 'Kubernetes', 'Containers', 'Orchestration'],
      durationHours: 38,
      domain: 'DevOps',
      knowledgeGraphWorkspaceId: 'python_backend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_12',
      title: 'PostgreSQL Database Design',
      keywords: ['PostgreSQL', 'SQL', 'Database Design', 'Indexing'],
      durationHours: 28,
      domain: 'Database',
      knowledgeGraphWorkspaceId: 'java_collections', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_13',
      title: 'System Design',
      keywords: ['System Design', 'Scalability', 'Microservices', 'Caching'],
      durationHours: 55,
      domain: 'Computer Science',
      knowledgeGraphWorkspaceId: 'python_backend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_14',
      title: 'Cloud Computing',
      keywords: ['Cloud', 'AWS', 'Azure', 'GCP'],
      durationHours: 40,
      domain: 'Cloud',
      knowledgeGraphWorkspaceId: 'react_frontend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_15',
      title: 'AWS Fundamentals',
      keywords: ['AWS', 'EC2', 'S3', 'Lambda'],
      durationHours: 35,
      domain: 'Cloud',
      knowledgeGraphWorkspaceId: 'python_backend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_16',
      title: 'C++ Programming',
      keywords: ['C++', 'OOP', 'Memory Management', 'STL'],
      durationHours: 48,
      domain: 'Backend',
      knowledgeGraphWorkspaceId: 'java_collections', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_17',
      title: 'Java OOP',
      keywords: ['Java', 'OOP', 'Design Patterns', 'SOLID'],
      durationHours: 30,
      domain: 'Backend',
      knowledgeGraphWorkspaceId: 'java_collections',
    ),
    CourseCatalogEntry(
      id: 'course_18',
      title: 'Operating Systems',
      keywords: ['OS', 'Linux', 'Memory Management', 'Concurrency'],
      durationHours: 50,
      domain: 'Computer Science',
      knowledgeGraphWorkspaceId: 'python_backend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_19',
      title: 'Computer Networks',
      keywords: ['Networking', 'TCP/IP', 'HTTP', 'DNS'],
      durationHours: 45,
      domain: 'Computer Science',
      knowledgeGraphWorkspaceId: 'python_backend', // Reusing available mock
    ),
    CourseCatalogEntry(
      id: 'course_20',
      title: 'Software Testing',
      keywords: ['Testing', 'TDD', 'JUnit', 'Selenium'],
      durationHours: 25,
      domain: 'QA',
      knowledgeGraphWorkspaceId: 'java_collections', // Reusing available mock
    ),
  ];

  static List<CourseCatalogEntry> getAllCourses() => _courses;

  static List<CourseCatalogEntry> getRecommendations(String? interviewDomain) {
    if (interviewDomain == null || interviewDomain.isEmpty) {
      return _courses.take(5).toList();
    }

    final lowerDomain = interviewDomain.toLowerCase();
    final matches = _courses.where((c) {
      if (c.domain.toLowerCase() == lowerDomain) return true;
      if (lowerDomain.contains('backend') && c.domain == 'Backend') return true;
      if (lowerDomain.contains('frontend') && c.domain == 'Frontend') return true;
      if (lowerDomain.contains('ai') && c.domain == 'AI/ML') return true;
      return false;
    }).toList();

    if (matches.length >= 5) {
      return matches.take(5).toList();
    } else {
      // Pad with default recommendations if not enough matches
      final needed = 5 - matches.length;
      final defaults = _courses.where((c) => !matches.contains(c)).take(needed).toList();
      return [...matches, ...defaults];
    }
  }

  static List<CourseCatalogEntry> search(String query) {
    if (query.isEmpty) return _courses;
    
    String normalized = query.toLowerCase().trim();
    
    // Typo corrections
    if (normalized == 'pyhton') normalized = 'python';
    if (normalized == 'sprng') normalized = 'spring';
    
    return _courses.where((c) {
      if (c.title.toLowerCase().contains(normalized)) return true;
      if (c.domain.toLowerCase().contains(normalized)) return true;
      for (final kw in c.keywords) {
        if (kw.toLowerCase().contains(normalized)) return true;
      }
      return false;
    }).toList();
  }
}
