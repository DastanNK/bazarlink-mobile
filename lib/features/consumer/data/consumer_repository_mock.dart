// lib/features/consumer/data/consumer_repository_mock.dart
import 'dart:async';
import '../domain/entities/consumer_models.dart';
import 'consumer_repository.dart';

class MockConsumerRepository implements ConsumerRepository {
  final List<Product> _products = [
    Product(id: 1, name: 'Chicken Breast', unit: 'kg', price: 1500),
    Product(id: 2, name: 'Tomatoes', unit: 'kg', price: 700),
    Product(id: 3, name: 'Cheese', unit: 'kg', price: 2500),
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
    LinkInfo(id: 1, supplierName: 'Best Meat Supplier', status: 'accepted'),
    LinkInfo(id: 2, supplierName: 'VeggieLand', status: 'pending'),
  ];

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
  Future<void> createOrder(Product product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _orders.add(
      ConsumerOrder(
        id: _orders.length + 1,
        createdAt: DateTime.now(),
        status: 'pending',
        total: product.price * 10,
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
}
