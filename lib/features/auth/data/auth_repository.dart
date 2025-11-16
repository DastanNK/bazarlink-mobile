// lib/features/auth/data/auth_repository.dart
import '../domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
  });

  Future<User?> getCurrentUser();

  Future<void> logout();
}
