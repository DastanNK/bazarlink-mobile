// lib/features/sales/domain/entities/manager_info.dart
class ManagerInfo {
  final int id;
  final String name;
  final String email;

  ManagerInfo({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ManagerInfo.fromJson(Map<String, dynamic> json) {
    return ManagerInfo(
      id: json['id'] as int,
      name: json['full_name'] as String? ?? json['name'] as String? ?? 'Manager',
      email: json['email'] as String? ?? '',
    );
  }
}

