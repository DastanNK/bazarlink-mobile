// lib/features/consumer/domain/entities/consumer_models.dart
class Product {
  final int id;
  final String name;
  final String unit;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
  });
}

class ConsumerOrder {
  final int id;
  final DateTime createdAt;
  final String status;
  final double total;

  ConsumerOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.total,
  });
}

class LinkInfo {
  final int id;
  final String supplierName;
  final String status; // pending / accepted / rejected / blocked

  LinkInfo({
    required this.id,
    required this.supplierName,
    required this.status,
  });
}

class Complaint {
  final int id;
  final String title;
  final String status;

  Complaint({
    required this.id,
    required this.title,
    required this.status,
  });
}
