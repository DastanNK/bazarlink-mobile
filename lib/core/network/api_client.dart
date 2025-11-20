// lib/core/network/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  /// ВАЖНО: если запускаешь Django на локале и тестируешь на эмуляторе Android —
  /// используй 10.0.2.2 вместо localhost.
  final String baseUrl;

  String? _token;

  ApiClient({
    this.baseUrl = 'http://10.0.2.2:8000/api/v1',
    // если тестируешь прямо на телефоне в одной сети с ноутом:
    // передай baseUrl типа 'http://192.168.0.10:8000/api/v1'
  });

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> get(String path) {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
  }

  Future<http.Response> post(
    String path, {
    Object? body,
  }) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> put(
    String path, {
    Object? body,
  }) {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path) {
    return http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
  }
}
