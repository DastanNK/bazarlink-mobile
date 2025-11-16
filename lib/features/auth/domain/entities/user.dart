// lib/features/auth/domain/entities/user.dart
import 'package:consumerapp/features/auth/domain/value_objects.dart';


class User {
  final int id;
  final String email;
  final UserRole role;
  final int? supplierId;
  final int? consumerId;

  const User({
    required this.id,
    required this.email,
    required this.role,
    this.supplierId,
    this.consumerId,
  });

  bool get isConsumer => role == UserRole.consumer;
  bool get isSalesRep => role == UserRole.salesRepresentative;
}
