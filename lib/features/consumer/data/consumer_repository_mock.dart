// lib/features/consumer/data/consumer_repository_mock.dart
import 'dart:async';
import '../domain/entities/consumer_models.dart';
import 'consumer_repository.dart';

class MockConsumerRepository implements ConsumerRepository {
  final List<Product> _products = [
    Product(id: 1, name: 'Chicken Breast', unit: 'kg', price: 1500, category: 'Meat', imageUrl: null),
    Product(id: 2, name: 'Tomatoes', unit: 'kg', price: 700, category: 'Vegetables', imageUrl: null),
    Product(id: 3, name: 'Cheese', unit: 'kg', price: 2500, category: 'Dairy', imageUrl: null),
    Product(id: 4, name: 'Apples', unit: 'kg', price: 500, category: 'Fruits', imageUrl: null),
    Product(id: 5, name: 'Beef', unit: 'kg', price: 2000, category: 'Meat', imageUrl: null),
    Product(id: 6, name: 'Carrots', unit: 'kg', price: 400, category: 'Vegetables', imageUrl: null),
    Product(id: 7, name: 'Bananas', unit: 'kg', price: 600, category: 'Fruits', imageUrl: null),
    Product(id: 8, name: 'Milk', unit: 'L', price: 800, category: 'Dairy', imageUrl: null),
  ];

  final List<ConsumerOrder> _orders = [
    ConsumerOrder(
      id: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'accepted',
      total: 45000,
    ),
    ConsumerOrder(
      id: 2,
      createdAt: DateTime.now(),
      status: 'pending',
      total: 12000,
    ),
  ];

  final List<LinkInfo> _links = [
    LinkInfo(id: 1, supplierName: 'Best Meat Supplier', status: 'accepted', supplierCode: 'BMS001'),
    LinkInfo(id: 2, supplierName: 'VeggieLand', status: 'accepted', supplierCode: 'VL001'),
  ];

  // Supplier products mapping: supplierCode -> List<SupplierProduct>
  final Map<String, List<SupplierProduct>> _supplierProducts = {
    'BMS001': [
      SupplierProduct(
        productId: 1,
        productName: 'Chicken Breast',
        category: 'Meat',
        imageUrl: null,
        supplierId: 1,
        supplierName: 'Best Meat Supplier',
        supplierCode: 'BMS001',
        price: 1500,
        discountPrice: 1350,
        currency: 'KZT',
        unit: 'kg',
      ),
      SupplierProduct(
        productId: 5,
        productName: 'Beef',
        category: 'Meat',
        imageUrl: null,
        supplierId: 1,
        supplierName: 'Best Meat Supplier',
        supplierCode: 'BMS001',
        price: 2000,
        discountPrice: 1800,
        currency: 'KZT',
        unit: 'kg',
      ),
    ],
    'VL001': [
      SupplierProduct(
        productId: 2,
        productName: 'Tomatoes',
        category: 'Vegetables',
        imageUrl: null,
        supplierId: 3,
        supplierName: 'VeggieLand',
        supplierCode: 'VL001',
        price: 700,
        discountPrice: 600,
        currency: 'KZT',
        unit: 'kg',
      ),
      SupplierProduct(
        productId: 6,
        productName: 'Carrots',
        category: 'Vegetables',
        imageUrl: null,
        supplierId: 3,
        supplierName: 'VeggieLand',
        supplierCode: 'VL001',
        price: 400,
        discountPrice: null,
        currency: 'KZT',
        unit: 'kg',
      ),
    ],
  };

  final Map<int, List<Supplier>> _productSuppliers = {
    1: [
      Supplier(
        id: 1,
        name: 'Best Meat Supplier',
        code: 'BMS001',
        description: 'Premium quality chicken breast, fresh daily',
        price: 1500,
        discountPrice: 1350,
        currency: 'KZT',
        stockQuantity: 50,
        unit: 'kg',
        minOrderQuantity: 5,
        deliveryAvailability: true,
        pickupAvailability: true,
        leadTimeDays: 1,
      ),
      Supplier(
        id: 2,
        name: 'Meat Masters',
        code: 'MM002',
        description: 'Organic free-range chicken breast',
        price: 1800,
        discountPrice: null,
        currency: 'KZT',
        stockQuantity: 30,
        unit: 'kg',
        minOrderQuantity: 3,
        deliveryAvailability: true,
        pickupAvailability: false,
        leadTimeDays: 2,
      ),
    ],
    2: [
      Supplier(
        id: 3,
        name: 'VeggieLand',
        code: 'VL001',
        description: 'Fresh local tomatoes, vine-ripened',
        price: 700,
        discountPrice: 600,
        currency: 'KZT',
        stockQuantity: 100,
        unit: 'kg',
        minOrderQuantity: 2,
        deliveryAvailability: true,
        pickupAvailability: true,
        leadTimeDays: 0,
      ),
    ],
    3: [
      Supplier(
        id: 4,
        name: 'Dairy Fresh',
        code: 'DF001',
        description: 'Premium quality cheese, aged to perfection',
        price: 2500,
        discountPrice: 2200,
        currency: 'KZT',
        stockQuantity: 40,
        unit: 'kg',
        minOrderQuantity: 1,
        deliveryAvailability: true,
        pickupAvailability: true,
        leadTimeDays: 1,
      ),
    ],
    4: [
      Supplier(
        id: 5,
        name: 'Fruit Paradise',
        code: 'FP001',
        description: 'Sweet and crisp apples, locally sourced',
        price: 500,
        discountPrice: null,
        currency: 'KZT',
        stockQuantity: 80,
        unit: 'kg',
        minOrderQuantity: 3,
        deliveryAvailability: true,
        pickupAvailability: false,
        leadTimeDays: 1,
      ),
    ],
    5: [
      Supplier(
        id: 1,
        name: 'Best Meat Supplier',
        code: 'BMS001',
        description: 'Premium quality beef, fresh and tender',
        price: 2000,
        discountPrice: 1800,
        currency: 'KZT',
        stockQuantity: 40,
        unit: 'kg',
        minOrderQuantity: 3,
        deliveryAvailability: true,
        pickupAvailability: true,
        leadTimeDays: 1,
      ),
    ],
    6: [
      Supplier(
        id: 3,
        name: 'VeggieLand',
        code: 'VL001',
        description: 'Fresh local carrots, crisp and sweet',
        price: 400,
        discountPrice: null,
        currency: 'KZT',
        stockQuantity: 150,
        unit: 'kg',
        minOrderQuantity: 2,
        deliveryAvailability: true,
        pickupAvailability: true,
        leadTimeDays: 0,
      ),
    ],
  };

  final List<Complaint> _complaints = [
    Complaint(id: 1, title: 'Late delivery', status: 'open'),
  ];

  @override
  Future<List<Product>> getCatalog() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _products;
  }

  @override
  Future<List<ConsumerOrder>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _orders;
  }

  @override
  Future<List<LinkInfo>> getLinks() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _links;
  }

  @override
  Future<List<Complaint>> getComplaints() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _complaints;
  }

  @override
  Future<void> createOrder(Product product, {int quantity = 1, int supplierId = 0}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _orders.add(
      ConsumerOrder(
        id: _orders.length + 1,
        createdAt: DateTime.now(),
        status: 'pending',
        total: product.price * quantity,
      ),
    );
  }

  @override
  Future<void> requestLink(String supplierCode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _links.add(
      LinkInfo(
        id: _links.length + 1,
        supplierName: 'Code=$supplierCode',
        status: 'pending',
        supplierCode: supplierCode,
      ),
    );
  }

  @override
  Future<void> createComplaint(int orderId, String text) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _complaints.add(
      Complaint(
        id: _complaints.length + 1,
        title: 'Order #$orderId: $text',
        status: 'open',
      ),
    );
  }

  @override
  Future<List<Supplier>> getSuppliersForProduct(int productId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _productSuppliers[productId] ?? [];
  }

  @override
  Future<bool> isLinkedToSupplier(String supplierCode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Check if supplier code matches any accepted links
    // For demo: BMS001, VL001 are linked (accepted), others are not
    final linkedCodes = ['BMS001', 'VL001'];
    return linkedCodes.contains(supplierCode.toUpperCase());
  }

  @override
  Future<List<LinkInfo>> getLinkedSuppliers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _links.where((link) => link.status == 'accepted').toList();
  }

  @override
  Future<List<String>> getCategoriesForSupplier(String supplierCode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final products = _supplierProducts[supplierCode.toUpperCase()] ?? [];
    final categories = products.map((p) => p.category).toSet().toList();
    return categories;
  }

  @override
  Future<List<SupplierProduct>> getProductsBySupplier(String supplierCode, {String? category}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var products = _supplierProducts[supplierCode.toUpperCase()] ?? [];
    if (category != null) {
      products = products.where((p) => p.category == category).toList();
    }
    return products;
  }

  @override
  Future<Supplier?> getSupplierDetailsForProduct(int productId, String supplierCode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Find supplier from productSuppliers map
    final suppliers = _productSuppliers[productId] ?? [];
    try {
      return suppliers.firstWhere(
        (s) => s.code.toUpperCase() == supplierCode.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
