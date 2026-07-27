import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://localhost:8080/api';
  static const String devToken = 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJmYjM4MDFjYy1iZTZhLTQyZjItOWVmYS1hOGQ2MzYzYTY3NWUiLCJlbWFpbCI6InRlc3RAb3Jlby5jb20iLCJpYXQiOjE3ODUxNjcxMTksImV4cCI6MTc4NTI1MzUxOX0.lr8cwxPgtBtPWOjvCV-a8csZJ8CmQZAMbfWYzsTh5Vtsep2k6Wg3U5uFAxzvKaCbR7U-VbhW6Mex7Q_dhKjp7w';

  final http.Client _client = http.Client();

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

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $devToken',
    };
  }
}
