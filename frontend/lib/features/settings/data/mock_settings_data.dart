class MockUser {
  String displayName;
  final String email;
  String bio;
  String country;
  final String avatarInitials;

  MockUser({
    required this.displayName,
    required this.email,
    required this.bio,
    required this.country,
    required this.avatarInitials,
  });

  static MockUser defaultUser() => MockUser(
        displayName: 'Priyaj Gawade',
        email: 'priyaj@gmail.com',
        bio: 'Backend Engineering Enthusiast',
        country: 'India',
        avatarInitials: 'PG',
      );
}

class MockSettings {
  String themeMode; // 'Dark', 'Light', 'System'
  String language; // 'English', 'Auto Detect'

  MockSettings({
    required this.themeMode,
    required this.language,
  });

  static MockSettings defaults() => MockSettings(
        themeMode: 'Dark',
        language: 'English',
      );
}

class MockNotificationPreferences {
  bool courseUpdates;
  bool communityAnnouncements;
  bool productUpdates;

  MockNotificationPreferences({
    required this.courseUpdates,
    required this.communityAnnouncements,
    required this.productUpdates,
  });

  static MockNotificationPreferences defaults() =>
      MockNotificationPreferences(
        courseUpdates: true,
        communityAnnouncements: false,
        productUpdates: true,
      );
}

class MockAboutInformation {
  final String version;
  final String releaseDate;
  final String githubUrl;
  final String supportEmail;

  const MockAboutInformation({
    required this.version,
    required this.releaseDate,
    required this.githubUrl,
    required this.supportEmail,
  });

  static const MockAboutInformation data = MockAboutInformation(
    version: '0.9.2-beta',
    releaseDate: 'July 2026',
    githubUrl: 'https://github.com/oreo-ai-tutor/oreo',
    supportEmail: 'support@oreo.ai',
  );
}
