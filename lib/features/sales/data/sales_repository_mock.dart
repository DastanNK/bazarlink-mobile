// lib/features/sales/data/sales_repository_mock.dart
import 'dart:async';

import '../domain/entities/sales_models.dart';
import 'sales_repository.dart';

class MockSalesRepository implements SalesRepository {
  final List<SalesConsumer> _consumers = [
    SalesConsumer(id: 1, name: 'Restaurant A', status: 'active'),
    SalesConsumer(id: 2, name: 'Hotel B', status: 'active'),
  ];

  final List<SalesOrder> _orders = [
    SalesOrder(
      id: 1,
      consumerName: 'Restaurant A',
      status: 'pending',
      total: 50000,
    ),
    SalesOrder(
      id: 2,
      consumerName: 'Hotel B',
      status: 'accepted',
      total: 80000,
    ),
  ];

  final List<SalesComplaint> _complaints = [
    SalesComplaint(
      id: 1,
      consumerName: 'Restaurant A',
      title: 'Damaged packaging',
      status: 'open',
    ),
  ];

  final Map<int, List<SalesMessage>> _messagesByConsumer = {
    1: [
      SalesMessage(
        id: 1,
        from: 'Restaurant A',
        text: 'Hello, delivery time?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      SalesMessage(
        id: 2,
        from: 'You',
        text: 'Hi! Planned at 16:00.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ],
  };

  @override
  Future<List<SalesConsumer>> getLinkedConsumers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _consumers;
  }

  @override
  Future<List<SalesOrder>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _orders;
  }

  @override
  Future<List<SalesComplaint>> getComplaints() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _complaints;
  }

  @override
  Future<List<SalesMessage>> getChatMessages(int consumerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _messagesByConsumer[consumerId] ?? [];
  }

  @override
  Future<void> acceptOrder(int orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = SalesOrder(
        id: _orders[idx].id,
        consumerName: _orders[idx].consumerName,
        status: 'accepted',
        total: _orders[idx].total,
      );
    }
  }

  @override
  Future<void> rejectOrder(int orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = SalesOrder(
        id: _orders[idx].id,
        consumerName: _orders[idx].consumerName,
        status: 'rejected',
        total: _orders[idx].total,
      );
    }
  }

  @override
  Future<void> sendMessage(int consumerId, String text) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = _messagesByConsumer.putIfAbsent(consumerId, () => []);
    list.add(
      SalesMessage(
        id: list.length + 1,
        from: 'You',
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }
}
