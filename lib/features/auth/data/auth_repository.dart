// lib/features/auth/data/auth_repository.dart
import '../domain/entities/consumer_registration.dart';
import '../domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
  });

  Future<User> registerConsumer(ConsumerSignUpData data);

  Future<User?> getCurrentUser();

  Future<void> logout();
}
