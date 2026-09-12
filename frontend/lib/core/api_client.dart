import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://localhost:8080/api';
  static const String wsUrl = 'ws://localhost:8080/ws/orchestration';
  
  // Singleton pattern so token is shared across instances
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;
  String? get token => _token;

  final http.Client _client = http.Client();

  void setToken(String? token) {
    _token = token;
  }

  Future<http.Response> get(String endpoint) async {
    return _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(),
    );
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    return _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    return _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(),
    );
  }

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }
}
