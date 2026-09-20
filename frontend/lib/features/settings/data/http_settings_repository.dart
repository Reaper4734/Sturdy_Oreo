import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import 'settings_model.dart';

class HttpSettingsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> fetchSettingsProfile() async {
    final response = await _apiClient.get('/settings/profile');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      final user = UserProfile(
        displayName: data['user']?['displayName'] ?? 'User',
        email: data['user']?['email'] ?? '',
        bio: data['user']?['bio'] ?? '',
        country: data['user']?['country'] ?? '',
        avatarInitials: data['user']?['avatarInitials'] ?? 'US',
      );

      final settings = AppThemeSettings(
        themeMode: data['settings']?['themeMode'] ?? 'Light',
        language: data['settings']?['language'] ?? 'English',
      );

      final notifications = NotificationPreferences(
        courseUpdates: data['notifications']?['courseUpdates'] ?? true,
        communityAnnouncements: data['notifications']?['communityAnnouncements'] ?? false,
        productUpdates: data['notifications']?['productUpdates'] ?? true,
      );
      
      return {
        'user': user,
        'settings': settings,
        'notifications': notifications,
      };
    }
    throw Exception('Failed to fetch settings');
  }

  Future<void> updateUserProfile(UserProfile user) async {
    final response = await _apiClient.put('/settings/profile', body: {
      'displayName': user.displayName,
      'bio': user.bio,
      'country': user.country,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }
}

final httpSettingsRepositoryProvider = Provider((ref) => HttpSettingsRepository());
