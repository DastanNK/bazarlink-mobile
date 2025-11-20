// lib/features/auth/data/auth_repository_mock.dart
import 'dart:async';

import '../domain/entities/consumer_registration.dart';
import '../domain/entities/user.dart';
import '../domain/value_objects.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  User? _currentUser;

  @override
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // простая заглушка: роль определяется по email
    if (email == 'sales@test.com') {
      _currentUser = User(
        id: 2,
        email: email,
        role: UserRole.sales_representative,
        supplierId: 200,
      );
    } else {
      _currentUser = User(
        id: 3,
        email: email,
        role: UserRole.owner,
        supplierId: 200,
      );
    }

    return _currentUser!;
  }

  @override
  Future<User> registerConsumer(ConsumerSignUpData data) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Create a mock consumer user
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch,
      email: data.email,
      role: UserRole.consumer,
      consumerId: (_currentUser?.consumerId ?? 100) + 1,
    );
    
    return _currentUser!;
  }

  @override
  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }
}
