// lib/features/sales/data/sales_repository_api.dart
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/entities/user.dart';
import '../domain/entities/sales_models.dart';
import 'sales_repository.dart';

class ApiSalesRepository implements SalesRepository {
  final ApiClient _client;
  final AuthRepository _authRepository;

  ApiSalesRepository(this._client, this._authRepository);

  Future<User> _ensureUser() async {
    final user = await _authRepository.getCurrentUser();
    if (user == null || user.supplierId == null) {
      throw Exception('Current user is not a supplier-side user');
    }
    return user;
  }

  @override
  Future<List<SalesConsumer>> getLinkedConsumers() async {
    final user = await _ensureUser();
    final supplierId = user.supplierId!;
    
    // Get all links for this supplier (including pending ones)
    final resp = await _client.get('/links/?supplier_id=$supplierId');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load consumers: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    final consumerIds = <int>{};
    final consumers = <SalesConsumer>[];

    for (final link in data) {
      final linkData = link as Map<String, dynamic>;
      final consumerId = linkData['consumer_id'] as int?;
      final status = linkData['status'] as String?;
      final linkId = linkData['id'] as int?;
      final assignedSalesRepId = linkData['assigned_sales_rep_id'] as int?;
      
      if (consumerId != null && linkId != null && !consumerIds.contains(consumerId)) {
        consumerIds.add(consumerId);
        // Get consumer details
        final consumerResp = await _client.get('/consumers/$consumerId');
        if (consumerResp.statusCode == 200) {
          final consumerJson = jsonDecode(consumerResp.body) as Map<String, dynamic>;
          final consumer = SalesConsumer.fromJson(consumerJson);
          // Update status from link and include linkId
          consumers.add(SalesConsumer(
            id: consumer.id,
            name: consumer.name,
            status: status ?? 'pending',
            city: consumer.city,
            linkId: linkId,
            assignedSalesRepId: assignedSalesRepId,
          ));
        }
      }
    }

    return consumers;
  }

  @override
  Future<List<SalesOrder>> getOrders() async {
    final resp = await _client.get('/orders/');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load orders: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => SalesOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<SalesComplaint>> getComplaints() async {
    final resp = await _client.get('/complaints/');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load complaints: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => SalesComplaint.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<SalesMessage>> getChatMessages(int linkId) async {
    final resp = await _client.get('/messages/?link_id=$linkId');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load messages: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => SalesMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> acceptOrder(int orderId) async {
    final body = {
      'status': 'accepted',
    };
    final resp = await _client.put('/orders/$orderId', body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to accept order: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> rejectOrder(int orderId) async {
    final body = {
      'status': 'rejected',
    };
    final resp = await _client.put('/orders/$orderId', body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to reject order: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> sendMessage(int linkId, String text) async {
    await _ensureUser();

    final body = {
      'content': text,
      'message_type': 'text',
      'attachment_url': null,
      'attachment_type': null,
      'product_id': null,
      'order_id': null,
      'link_id': linkId,
      'receiver_id': null,
    };

    final resp = await _client.post('/messages/', body: body);
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception('Failed to send message: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> resolveComplaint(int complaintId, {required String resolution}) async {
    final body = {
      'status': 'resolved',
      'resolution': resolution,
    };
    final resp = await _client.put('/complaints/$complaintId', body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to resolve complaint: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> escalateComplaint(
    int complaintId, {
    required int managerUserId,
    String? note,
  }) async {
    final body = {
      'escalated_to_user_id': managerUserId,
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final resp = await _client.post('/complaints/$complaintId/escalate', body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to escalate complaint: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> acceptLink(int linkId) async {
    // Update link status to "accepted"
    final body = {
      'status': 'accepted',
      'assigned_sales_rep_id': null, // Will be assigned later
    };
    final resp = await _client.put('/links/$linkId', body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to accept link: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> rejectLink(int linkId) async {
    // Update link status to "rejected"
    final body = {
      'status': 'rejected',
    };
    final resp = await _client.put('/links/$linkId', body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to reject link: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> assignLink(int linkId) async {
    // Assign link to current sales representative
    final resp = await _client.post('/links/$linkId/assign');
    if (resp.statusCode != 200) {
      throw Exception('Failed to assign link: ${resp.statusCode} ${resp.body}');
    }
  }
}

