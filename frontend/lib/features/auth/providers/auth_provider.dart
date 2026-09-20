import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? userId;
  final String? error;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.token,
    this.userId,
    this.error,
    this.isLoading = true,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    String? userId,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient = ApiClient();

  AuthNotifier() : super(AuthState()) {
    _initGoogleSignIn();
    _checkSavedToken();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize(
        clientId: const String.fromEnvironment(
          'GOOGLE_CLIENT_ID',
          defaultValue: '591562728024-n2v4rgro07374dm04cn5dj79e2t8gnv7.apps.googleusercontent.com',
        ),
      );
      GoogleSignIn.instance.authenticationEvents.listen((event) async {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final auth = event.user.authentication;
          if (auth.idToken != null) {
            final response = await _apiClient.post('/auth/google', body: {
              'idToken': auth.idToken,
            });
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              await _saveAuthData(data);
            } else {
              String errorMsg = 'Google auth failed on server';
              try {
                final errorData = jsonDecode(response.body);
                if (errorData is Map && errorData['detail'] != null) {
                  errorMsg = errorData['detail'].toString();
                }
              } catch (_) {}
              state = state.copyWith(isLoading: false, error: errorMsg);
            }
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _checkSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('auth_user_id');

    if (token != null && token.isNotEmpty) {
      _apiClient.setToken(token);
      
      try {
        // Validate token securely by hitting an authenticated endpoint
        final response = await _apiClient.get('/settings/profile');
        if (response.statusCode == 200) {
          state = state.copyWith(isAuthenticated: true, token: token, userId: userId, isLoading: false);
        } else {
          // Token is invalid, expired, or user deleted from DB
          await logout();
        }
      } catch (e) {
        // Fallback to logout if backend connection fails during validation
        await logout();
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post('/auth/login', body: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data);
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid email or password');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed: $e');
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post('/auth/register', body: {
        'email': email,
        'password': password,
        'displayName': displayName,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data);
      } else {
        state = state.copyWith(isLoading: false, error: 'Registration failed');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed: $e');
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Google ID Token is null');
      }

      final response = await _apiClient.post('/auth/google', body: {
        'idToken': googleAuth.idToken,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data);
      } else {
        String errorMsg = 'Google auth failed on server';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData['detail'] != null) {
            errorMsg = errorData['detail'].toString();
          }
        } catch (_) {}
        state = state.copyWith(isLoading: false, error: errorMsg);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google login failed: $e');
    }
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final token = data['token'];
    final userId = data['userId'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user_id', userId ?? '');

    _apiClient.setToken(token);
    state = state.copyWith(isAuthenticated: true, token: token, userId: userId, isLoading: false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user_id');
    _apiClient.setToken(null);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    state = AuthState(isLoading: false);
  }
}
