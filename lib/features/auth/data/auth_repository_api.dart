// lib/features/auth/data/auth_repository_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../domain/entities/consumer_registration.dart';
import '../domain/entities/user.dart';
import '../domain/value_objects.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _client;

  User? _currentUser;

  ApiAuthRepository(this._client);

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    // OAuth2 Password Flow: /api/v1/auth/login
    final uri = Uri.parse('${_client.baseUrl}/auth/login');

    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': email,
        'password': password,
        'scope': '',
        'grant_type': 'password',
        'client_id': '',
        'client_secret': '',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Login failed: ${resp.statusCode} ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null) {
      throw Exception('No access_token in response');
    }

    _client.setToken(accessToken);

    // сразу дергаем /auth/me
    final meResp = await _client.get('/auth/me');
    if (meResp.statusCode != 200) {
      throw Exception('Failed to load user: ${meResp.statusCode} ${meResp.body}');
    }

    final meData = jsonDecode(meResp.body) as Map<String, dynamic>;
    _currentUser = _userFromJson(meData);
    return _currentUser!;
  }

  @override
  Future<User> registerConsumer(ConsumerSignUpData data) async {
    final resp = await _client.post(
      '/auth/register-consumer',
      body: data.toJson(),
    );
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception(
        'Registration failed: ${resp.statusCode} ${resp.body}',
      );
    }
    // После регистрации автоматически логинимся
    return login(email: data.email, password: data.password);
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final resp = await _client.get('/auth/me');
    if (resp.statusCode != 200) {
      return null;
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    _currentUser = _userFromJson(data);
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _client.setToken(null);
    _currentUser = null;
  }

  User _userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      supplierId: json['supplier_id'] as int?,
      consumerId: json['consumer_id'] as int?,
    );
  }
}

