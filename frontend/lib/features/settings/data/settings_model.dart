class UserProfile {
  String displayName;
  String email;
  String bio;
  String country;
  String avatarInitials;

  UserProfile({
    required this.displayName,
    required this.email,
    required this.bio,
    required this.country,
    required this.avatarInitials,
  });

  static UserProfile defaultUser() => UserProfile(
        displayName: 'Anjali Gupta',
        email: 'anjali.g@example.com',
        bio: 'AI Researcher & Distributed Systems Engineer. Exploring the intersection of edge computing and LLMs.',
        country: 'India',
        avatarInitials: 'AG',
      );
}

class AppThemeSettings {
  String themeMode; // 'Dark', 'Light', 'System'
  String language;

  AppThemeSettings({
    required this.themeMode,
    required this.language,
  });

  static AppThemeSettings defaults() => AppThemeSettings(
        themeMode: 'Dark',
        language: 'English',
      );
}

class NotificationPreferences {
  bool courseUpdates;
  bool communityAnnouncements;
  bool productUpdates;

  NotificationPreferences({
    required this.courseUpdates,
    required this.communityAnnouncements,
    required this.productUpdates,
  });

  static NotificationPreferences defaults() =>
      NotificationPreferences(
        courseUpdates: true,
        communityAnnouncements: false,
        productUpdates: true,
      );
}

class AboutInformation {
  final String appVersion;
  final String termsOfServiceUrl;
  final String privacyPolicyUrl;

  const AboutInformation({
    required this.appVersion,
    required this.termsOfServiceUrl,
    required this.privacyPolicyUrl,
  });

  static const AboutInformation data = AboutInformation(
    appVersion: '1.0.0 (Build 42)',
    termsOfServiceUrl: 'https://example.com/terms',
    privacyPolicyUrl: 'https://example.com/privacy',
  );
}
