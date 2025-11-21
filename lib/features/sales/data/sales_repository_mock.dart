// lib/features/sales/data/sales_repository_mock.dart
import 'dart:async';

import '../domain/entities/sales_models.dart';
import '../domain/entities/manager_info.dart';
import 'sales_repository.dart';

class MockSalesRepository implements SalesRepository {
  final List<SalesConsumer> _consumers = [
    SalesConsumer(id: 1, name: 'Restaurant A', status: 'pending', linkId: 1),
    SalesConsumer(id: 2, name: 'Hotel B', status: 'accepted', linkId: 2, assignedSalesRepId: 1),
  ];

  final List<SalesOrder> _orders = [
    SalesOrder(
      id: 1,
      consumerName: 'Restaurant A',
      status: 'pending',
      total: 50000,
      orderNumber: 'ORD-001',
      currency: 'KZT',
    ),
    SalesOrder(
      id: 2,
      consumerName: 'Hotel B',
      status: 'accepted',
      total: 80000,
      orderNumber: 'ORD-002',
      currency: 'KZT',
    ),
  ];

  final List<SalesComplaint> _complaints = [
    SalesComplaint(
      id: 1,
      consumerName: 'Restaurant A',
      title: 'Damaged packaging',
      status: 'open',
      description: 'Products arrived with damaged packaging',
    ),
  ];

  final Map<int, List<SalesMessage>> _messagesByLink = {
    1: [
      SalesMessage(
        id: 1,
        from: 'Restaurant A',
        text: 'Hello, delivery time?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        linkId: 1,
        senderId: 1, // Consumer
      ),
      SalesMessage(
        id: 2,
        from: 'You',
        text: 'Hi! Planned at 16:00.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        linkId: 1,
        senderId: 5, // Sales rep (current user)
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
  Future<List<SalesMessage>> getChatMessages(int linkId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _messagesByLink[linkId] ?? [];
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
        orderNumber: _orders[idx].orderNumber,
        currency: _orders[idx].currency,
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
        orderNumber: _orders[idx].orderNumber,
        currency: _orders[idx].currency,
      );
    }
  }

  @override
  Future<void> sendMessage(int linkId, String text) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = _messagesByLink.putIfAbsent(linkId, () => []);
    list.add(
      SalesMessage(
        id: list.length + 1,
        from: 'You',
        text: text,
        createdAt: DateTime.now(),
        linkId: linkId,
        senderId: 5, // Sales rep (current user)
      ),
    );
  }

  @override
  Future<void> resolveComplaint(int complaintId, {required String resolution}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _complaints.indexWhere((c) {
      return c.id == complaintId;
    });
    if (idx != -1) {
      final old = _complaints[idx];
      _complaints[idx] = SalesComplaint(
        id: old.id,
        consumerName: old.consumerName,
        title: old.title,
        status: 'resolved',
        description: old.description,
      );
    }
  }

  @override
  Future<void> escalateComplaint(
    int complaintId, {
    required int managerUserId,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _complaints.indexWhere((c) => c.id == complaintId);
    if (idx != -1) {
      _complaints[idx] = SalesComplaint(
        id: _complaints[idx].id,
        consumerName: _complaints[idx].consumerName,
        title: _complaints[idx].title,
        status: 'escalated',
        description: _complaints[idx].description,
      );
    }
  }

  @override
  Future<void> acceptLink(int linkId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _consumers.indexWhere((c) => c.linkId == linkId);
    if (idx != -1) {
      _consumers[idx] = SalesConsumer(
        id: _consumers[idx].id,
        name: _consumers[idx].name,
        status: 'accepted',
        city: _consumers[idx].city,
        linkId: _consumers[idx].linkId,
        assignedSalesRepId: _consumers[idx].assignedSalesRepId,
      );
    }
  }

  @override
  Future<void> rejectLink(int linkId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _consumers.indexWhere((c) => c.linkId == linkId);
    if (idx != -1) {
      _consumers[idx] = SalesConsumer(
        id: _consumers[idx].id,
        name: _consumers[idx].name,
        status: 'rejected',
        city: _consumers[idx].city,
        linkId: _consumers[idx].linkId,
        assignedSalesRepId: _consumers[idx].assignedSalesRepId,
      );
    }
  }

  @override
  Future<void> assignLink(int linkId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _consumers.indexWhere((c) => c.linkId == linkId);
    if (idx != -1) {
      _consumers[idx] = SalesConsumer(
        id: _consumers[idx].id,
        name: _consumers[idx].name,
        status: _consumers[idx].status,
        city: _consumers[idx].city,
        linkId: _consumers[idx].linkId,
        assignedSalesRepId: 1, // Mock assigned to current user
      );
    }
  }

  @override
  Future<void> cancelOrder(int orderId, {required String reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = SalesOrder(
        id: _orders[idx].id,
        consumerName: _orders[idx].consumerName,
        status: 'cancelled',
        total: _orders[idx].total,
        orderNumber: _orders[idx].orderNumber,
        currency: _orders[idx].currency,
      );
    }
  }

  @override
  Future<void> completeOrder(int orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = SalesOrder(
        id: _orders[idx].id,
        consumerName: _orders[idx].consumerName,
        status: 'completed',
        total: _orders[idx].total,
        orderNumber: _orders[idx].orderNumber,
        currency: _orders[idx].currency,
      );
    }
  }

  @override
  Future<void> cancelLink(int linkId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _consumers.indexWhere((c) => c.linkId == linkId);
    if (idx != -1) {
      _consumers[idx] = SalesConsumer(
        id: _consumers[idx].id,
        name: _consumers[idx].name,
        status: 'removed',
        city: _consumers[idx].city,
        linkId: _consumers[idx].linkId,
        assignedSalesRepId: null,
      );
    }
  }

  @override
  Future<void> blockConsumer(int consumerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _consumers.indexWhere((c) => c.id == consumerId);
    if (idx != -1) {
      _consumers[idx] = SalesConsumer(
        id: _consumers[idx].id,
        name: _consumers[idx].name,
        status: 'blocked',
        city: _consumers[idx].city,
        linkId: _consumers[idx].linkId,
        assignedSalesRepId: _consumers[idx].assignedSalesRepId,
      );
    }
  }

  @override
  Future<List<ManagerInfo>> getManagers() async {
    return [
      ManagerInfo(id: 1, name: 'Manager One', email: 'manager1@example.com'),
      ManagerInfo(id: 2, name: 'Manager Two', email: 'manager2@example.com'),
    ];
  }
}
