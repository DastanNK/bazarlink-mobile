// lib/features/consumer/domain/entities/cart_item.dart
class CartItem {
  final int productId;
  final String productName;
  final int supplierId;
  final String supplierCode;
  final double price;
  final double? discountPrice;
  final String currency;
  final String unit;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.supplierId,
    required this.supplierCode,
    required this.price,
    this.discountPrice,
    required this.currency,
    required this.unit,
    required this.quantity,
  });

  double get totalPrice {
    final effectivePrice = discountPrice ?? price;
    return effectivePrice * quantity;
  }
}

