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

  static UserProfile empty() => UserProfile(
        displayName: '',
        email: '',
        bio: '',
        country: '',
        avatarInitials: '',
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
        themeMode: 'Light',
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
