// lib/features/sales/data/sales_repository_api.dart
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/entities/user.dart';
import '../domain/entities/sales_models.dart';
import '../domain/entities/manager_info.dart';
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
      final requestMessage = linkData['request_message'] as String?;
      
      if (consumerId != null && linkId != null && !consumerIds.contains(consumerId)) {
        consumerIds.add(consumerId);
        // Get consumer details
        final consumerResp = await _client.get('/consumers/$consumerId');
        if (consumerResp.statusCode == 200) {
          final consumerJson = jsonDecode(consumerResp.body) as Map<String, dynamic>;
          final consumer = SalesConsumer.fromJson(consumerJson);
          // Update status from link and include linkId and request message
          consumers.add(SalesConsumer(
            id: consumer.id,
            name: consumer.name,
            status: status ?? 'pending',
            city: consumer.city,
            linkId: linkId,
            assignedSalesRepId: assignedSalesRepId,
            requestMessage: requestMessage,
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
    
    // Get consumer IDs and fetch names
    final consumerIds = <int>{};
    for (final order in data) {
      final orderData = order as Map<String, dynamic>;
      final consumerId = orderData['consumer_id'] as int?;
      if (consumerId != null) {
        consumerIds.add(consumerId);
      }
    }
    
    final consumerNames = <int, String>{};
    for (final consumerId in consumerIds) {
      try {
        final consumerResp = await _client.get('/consumers/$consumerId');
        if (consumerResp.statusCode == 200) {
          final consumerJson = jsonDecode(consumerResp.body) as Map<String, dynamic>;
          final name = consumerJson['business_name'] as String? ?? consumerJson['name'] as String?;
          if (name != null) {
            consumerNames[consumerId] = name;
          }
        }
      } catch (e) {
        // If fetching fails, use default name
      }
    }
    
    // Get product IDs from all order items and fetch product names
    final productIds = <int>{};
    for (final order in data) {
      final orderData = order as Map<String, dynamic>;
      final items = orderData['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final itemData = item as Map<String, dynamic>;
        final productId = itemData['product_id'] as int?;
        if (productId != null) {
          productIds.add(productId);
        }
      }
    }
    
    final productNames = <int, String>{};
    for (final productId in productIds) {
      try {
        final productResp = await _client.get('/products/$productId');
        if (productResp.statusCode == 200) {
          final productJson = jsonDecode(productResp.body) as Map<String, dynamic>;
          final name = productJson['name'] as String?;
          if (name != null) {
            productNames[productId] = name;
          }
        }
      } catch (e) {
        // If fetching fails, use default name
      }
    }
    
    return data.map((e) {
      final orderData = e as Map<String, dynamic>;
      final consumerId = orderData['consumer_id'] as int?;
      // Update order items with product names
      final items = orderData['items'] as List<dynamic>? ?? [];
      final itemsWithNames = items.map((item) {
        final itemData = item as Map<String, dynamic>;
        final productId = itemData['product_id'] as int?;
        if (productId != null && productNames.containsKey(productId)) {
          itemData['product_name'] = productNames[productId];
        }
        return itemData;
      }).toList();
      orderData['items'] = itemsWithNames;
      
      return SalesOrder.fromJson(orderData, consumerName: consumerId != null ? consumerNames[consumerId] : null);
    }).toList();
  }

  @override
  Future<List<SalesComplaint>> getComplaints() async {
    final resp = await _client.get('/complaints/');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load complaints: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    
    // Get consumer IDs and fetch names
    final consumerIds = <int>{};
    for (final complaint in data) {
      final complaintData = complaint as Map<String, dynamic>;
      final consumerId = complaintData['consumer_id'] as int?;
      if (consumerId != null) {
        consumerIds.add(consumerId);
      }
    }
    
    final consumerNames = <int, String>{};
    for (final consumerId in consumerIds) {
      try {
        final consumerResp = await _client.get('/consumers/$consumerId');
        if (consumerResp.statusCode == 200) {
          final consumerJson = jsonDecode(consumerResp.body) as Map<String, dynamic>;
          final name = consumerJson['business_name'] as String? ?? consumerJson['name'] as String?;
          if (name != null) {
            consumerNames[consumerId] = name;
          }
        }
      } catch (e) {
        // If fetching fails, use default name
      }
    }
    
    return data.map((e) {
      final complaintData = e as Map<String, dynamic>;
      final consumerId = complaintData['consumer_id'] as int?;
      return SalesComplaint.fromJson(complaintData, consumerName: consumerId != null ? consumerNames[consumerId] : null);
    }).toList();
  }

  @override
  Future<List<SalesMessage>> getChatMessages(int linkId) async {
    final resp = await _client.get('/messages/?link_id=$linkId');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load messages: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    
    // Get current user to determine sender role
    final user = await _ensureUser();
    final currentUserId = user.id;
    
    return data.map((e) {
      final json = e as Map<String, dynamic>;
      final senderId = json['sender_id'] as int?;
      final isFromCurrentUser = senderId == currentUserId;
      
      // Determine sender role
      String? senderRole;
      if (json['sender_role'] != null) {
        final role = json['sender_role'] as String;
        if (role == 'manager' || role == 'MANAGER') {
          senderRole = 'manager';
        } else if (role == 'sales' || role == 'SALES_REPRESENTATIVE') {
          senderRole = 'sales';
        }
      } else if (!isFromCurrentUser && senderId != null) {
        // If not from current user and no explicit role, try to determine from user info
        // For now, default to 'sales' if not explicitly manager
        senderRole = 'sales';
      }
      
      // Add sender_role to the JSON before parsing
      final messageJson = Map<String, dynamic>.from(json);
      messageJson['sender_role'] = senderRole;
      
      return SalesMessage.fromJson(messageJson);
    }).toList();
  }

  @override
  Future<void> acceptOrder(int orderId) async {
    final body = {
      'status': 'in_progress',
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
    // Update link status to "removed" (not "rejected" - links use REMOVED status)
    final body = {
      'status': 'removed',
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

  @override
  Future<void> cancelOrder(int orderId, {required String reason}) async {
    // Update order status to "cancelled" (note: backend uses "cancelled" not "canceled")
    final body = {
      'status': 'cancelled',
      'notes': reason, // Store cancel reason in notes
    };
    final resp = await _client.put('/orders/$orderId', body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to cancel order: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> completeOrder(int orderId) async {
    // Update order status to "completed"
    final body = {
      'status': 'completed',
    };
    final resp = await _client.put('/orders/$orderId', body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to complete order: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> cancelLink(int linkId) async {
    // Update link status to "removed" to unlink customer
    final body = {
      'status': 'removed',
    };
    final resp = await _client.put('/links/$linkId', body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to cancel link: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> blockConsumer(int consumerId) async {
    // Find all links with this consumer and block them
    final user = await _ensureUser();
    final supplierId = user.supplierId!;
    
    // Get all links for this supplier and consumer
    final resp = await _client.get('/links/?supplier_id=$supplierId&consumer_id=$consumerId');
    if (resp.statusCode != 200) {
      throw Exception('Failed to get links: ${resp.statusCode} ${resp.body}');
    }
    
    final data = jsonDecode(resp.body) as List<dynamic>;
    for (final link in data) {
      final linkData = link as Map<String, dynamic>;
      final linkId = linkData['id'] as int?;
      if (linkId != null) {
        // Update link status to "blocked"
        final body = {
          'status': 'blocked',
        };
        final updateResp = await _client.put('/links/$linkId', body: body);
        if (updateResp.statusCode != 200) {
          throw Exception('Failed to block consumer: ${updateResp.statusCode} ${updateResp.body}');
        }
      }
    }
  }

  @override
  Future<List<ManagerInfo>> getManagers() async {
    final user = await _ensureUser();
    final supplierId = user.supplierId!;
    
    // Get all users for this supplier with role MANAGER
    final resp = await _client.get('/users/?supplier_id=$supplierId&role=manager');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load managers: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => ManagerInfo.fromJson(e as Map<String, dynamic>)).toList();
  }
}

