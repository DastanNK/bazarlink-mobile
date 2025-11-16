// lib/features/consumer/presentation/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../domain/entities/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void addItem(CartItem item) {
    // Check if item already exists (same product and supplier)
    final existingIndex = _items.indexWhere(
      (i) => i.productId == item.productId && i.supplierCode == item.supplierCode,
    );

    if (existingIndex >= 0) {
      // Update quantity if exists
      _items[existingIndex].quantity += item.quantity;
    } else {
      // Add new item
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(int productId, String supplierCode) {
    _items.removeWhere(
      (item) => item.productId == productId && item.supplierCode == supplierCode,
    );
    notifyListeners();
  }

  void updateQuantity(int productId, String supplierCode, int quantity) {
    final index = _items.indexWhere(
      (i) => i.productId == productId && i.supplierCode == supplierCode,
    );
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

