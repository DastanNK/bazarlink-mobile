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
  final int? supplierId;
  final String? supplierCode;

  ConsumerOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.total,
    this.supplierId,
    this.supplierCode,
  });
}

class LinkInfo {
  final int id;
  final String supplierName;
  final String status; // pending / accepted / rejected / blocked
  final String? supplierCode;
  final String? city;
  final String? logoUrl;

  LinkInfo({
    required this.id,
    required this.supplierName,
    required this.status,
    this.supplierCode,
    this.city,
    this.logoUrl,
  });
}

class SupplierInfo {
  final int id;
  final String name;
  final String code;
  final String? city;
  final String? logoUrl;
  final String? status; // null if not linked, otherwise same as LinkInfo.status
  final String? category; // e.g., "Meat & Poultry", "Dairy", "Produce"
  final String? description;
  final String? address;
  final List<String>? deliveryRegions;
  final double? minOrderAmount;
  final String? paymentTerms;
  final String? deliverySchedule;
  final String? phone;
  final String? email;
  final String? website;
  final String? workingHours;
  final List<String>? productCategories;

  SupplierInfo({
    required this.id,
    required this.name,
    required this.code,
    this.city,
    this.logoUrl,
    this.status,
    this.category,
    this.description,
    this.address,
    this.deliveryRegions,
    this.minOrderAmount,
    this.paymentTerms,
    this.deliverySchedule,
    this.phone,
    this.email,
    this.website,
    this.workingHours,
    this.productCategories,
  });
}

class Complaint {
  final int id;
  final String title;
  final String status;
  final int orderId;
  final int? supplierId;
  final String? supplierCode;

  Complaint({
    required this.id,
    required this.title,
    required this.status,
    required this.orderId,
    this.supplierId,
    this.supplierCode,
  });
}

class Chat {
  final int id;
  final int supplierId;
  final String supplierName;
  final String? supplierCode;
  final String? supplierLogoUrl;
  final DateTime lastMessageAt;
  final bool isComplaint; // Highlight with red border if true
  final int? complaintId; // Link to complaint if this is a complaint chat

  Chat({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    this.supplierCode,
    this.supplierLogoUrl,
    required this.lastMessageAt,
    this.isComplaint = false,
    this.complaintId,
  });
}

class ChatMessage {
  final int id;
  final int chatId;
  final String text;
  final bool isFromConsumer;
  final DateTime createdAt;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.text,
    required this.isFromConsumer,
    required this.createdAt,
    this.imageUrl,
  });
}
