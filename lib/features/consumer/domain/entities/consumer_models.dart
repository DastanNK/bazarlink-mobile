// lib/features/consumer/domain/entities/consumer_models.dart
class Product {
  final int id;
  final String name;
  final String unit;
  final double price;
  final String category;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.category,
    this.imageUrl,
  });
}

class Supplier {
  final int id;
  final String name;
  final String code;
  final String? description;
  final double price;
  final double? discountPrice;
  final String currency;
  final int stockQuantity;
  final String unit;
  final int minOrderQuantity;
  final bool deliveryAvailability;
  final bool pickupAvailability;
  final int leadTimeDays;

  Supplier({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.price,
    this.discountPrice,
    required this.currency,
    required this.stockQuantity,
    required this.unit,
    required this.minOrderQuantity,
    required this.deliveryAvailability,
    required this.pickupAvailability,
    required this.leadTimeDays,
  });
}

class SupplierProduct {
  final int productId;
  final String productName;
  final String category;
  final String? imageUrl;
  final int supplierId;
  final String supplierName;
  final String supplierCode;
  final double price;
  final double? discountPrice;
  final String currency;
  final String unit;

  SupplierProduct({
    required this.productId,
    required this.productName,
    required this.category,
    this.imageUrl,
    required this.supplierId,
    required this.supplierName,
    required this.supplierCode,
    required this.price,
    this.discountPrice,
    required this.currency,
    required this.unit,
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
  final String? supplierCode;

  LinkInfo({
    required this.id,
    required this.supplierName,
    required this.status,
    this.supplierCode,
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
